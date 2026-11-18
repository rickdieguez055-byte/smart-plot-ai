"""Model inference service with fallback safety for room relationship predictions."""
import json
import logging
import os
from typing import Dict, List, Optional, Tuple

import joblib
import pandas as pd

from backend.app.engine.dimension_estimator import RoomSpecification
from backend.app.ml.features import RoomEntity, extract_pair_features
from backend.app.ml.taxonomy import map_room_label
from backend.app.schemas.plot import PlotInput

logger = logging.getLogger("smartplot.ml.model")

ARTIFACTS_DIR = os.path.join(os.path.dirname(__file__), "artifacts")


class RoomRelationshipPredictor:
    """Inference engine loading trained ML models with graceful architectural fallback."""

    _instance: Optional["RoomRelationshipPredictor"] = None

    def __init__(self, artifacts_dir: str = ARTIFACTS_DIR):
        self.artifacts_dir = artifacts_dir
        self.preprocessor = None
        self.rf_door = None
        self.rf_adj = None
        self.calibrator = None
        self.is_loaded = False
        self.model_version = "heuristic_fallback"
        self.door_threshold = 0.50
        self.adj_threshold = 0.34
        self._load_artifacts()

    @classmethod
    def get_instance(cls) -> "RoomRelationshipPredictor":
        if cls._instance is None:
            cls._instance = RoomRelationshipPredictor()
        return cls._instance

    def _load_artifacts(self) -> None:
        # Check for V2 artifacts first
        prep_v2 = os.path.join(self.artifacts_dir, "preprocessor_v2.joblib")
        door_v2 = os.path.join(self.artifacts_dir, "rf_door_v2.joblib")
        adj_v2 = os.path.join(self.artifacts_dir, "rf_adj_v2.joblib")
        thresh_v2 = os.path.join(self.artifacts_dir, "v2_thresholds.json")

        if os.path.exists(prep_v2) and os.path.exists(door_v2) and os.path.exists(adj_v2):
            try:
                self.preprocessor = joblib.load(prep_v2)
                self.rf_door = joblib.load(door_v2)
                self.rf_adj = joblib.load(adj_v2)
                if os.path.exists(thresh_v2):
                    with open(thresh_v2, "r", encoding="utf-8") as f:
                        t_data = json.load(f)
                        self.door_threshold = float(t_data.get("door_optimal_threshold", 0.50))
                        self.adj_threshold = float(t_data.get("adjacency_optimal_threshold", 0.34))
                self.is_loaded = True
                self.model_version = "v2"
                logger.info(f"Successfully loaded ML V2 models (door_threshold={self.door_threshold}, adj_threshold={self.adj_threshold}).")
                return
            except Exception as e:
                logger.warning(f"Failed to load ML V2 artifacts: {e}. Attempting V1 baseline.")

        # Fallback to V1 artifacts
        prep_v1 = os.path.join(self.artifacts_dir, "preprocessor.joblib")
        door_v1 = os.path.join(self.artifacts_dir, "rf_door_model.joblib")
        adj_v1 = os.path.join(self.artifacts_dir, "rf_adj_model.joblib")

        if os.path.exists(prep_v1) and os.path.exists(door_v1) and os.path.exists(adj_v1):
            try:
                self.preprocessor = joblib.load(prep_v1)
                self.rf_door = joblib.load(door_v1)
                self.rf_adj = joblib.load(adj_v1)
                self.door_threshold = 0.40
                self.adj_threshold = 0.50
                self.is_loaded = True
                self.model_version = "v1"
                logger.info("Successfully loaded ML V1 baseline models.")
            except Exception as e:
                logger.warning(f"Failed to load ML V1 artifacts: {e}. Fallback enabled.")
                self.is_loaded = False
                self.model_version = "heuristic_fallback"
        else:
            logger.info("ML model artifacts not yet found on disk. Operating in heuristic fallback mode.")
            self.is_loaded = False
            self.model_version = "heuristic_fallback"

    def predict_pair_relationship(
        self,
        plot: PlotInput,
        rooms: List[RoomSpecification],
    ) -> Dict[Tuple[str, str], Dict[str, float]]:
        """
        Predicts door connectivity probability and wall adjacency probability for all room pairs.
        
        Returns:
            Dict mapping (room_id_1, room_id_2) -> {
                "door_prob": float (0.0 to 1.0),
                "adj_prob": float (0.0 to 1.0),
                "recommended_adjacent": bool,
                "recommended_door": bool,
            }
        """
        # If model is not loaded, use deterministic architectural fallback
        if not self.is_loaded:
            return self._heuristic_fallback(plot, rooms)

        try:
            total_area = float(plot.plot_length * plot.plot_width)
            buildable_w = float(plot.plot_width)
            buildable_l = float(plot.plot_length)
            if plot.setbacks:
                buildable_w -= (plot.setbacks.left + plot.setbacks.right)
                buildable_l -= (plot.setbacks.front + plot.setbacks.rear)

            n_rooms = len(rooms)
            room_entities = [
                RoomEntity(
                    id=r.id,
                    raw_label=r.category.upper(),
                    category=r.category,
                    area=r.target_area,
                )
                for r in rooms
            ]
            room_counts = {}
            for r in room_entities:
                room_counts[r.category] = room_counts.get(r.category, 0) + 1

            pair_records = []
            pair_keys = []

            for i in range(n_rooms):
                for j in range(i + 1, n_rooms):
                    r1 = room_entities[i]
                    r2 = room_entities[j]
                    feat = extract_pair_features(
                        r1=r1,
                        r2=r2,
                        total_rooms=n_rooms,
                        plot_width=buildable_w,
                        plot_length=buildable_l,
                        total_area=total_area,
                        room_counts=room_counts,
                    )
                    pair_records.append(feat)
                    pair_keys.append((r1.id, r2.id))

            if not pair_records:
                return {}

            df_pairs = pd.DataFrame(pair_records)
            X = self.preprocessor.transform(df_pairs)

            door_probs = self.rf_door.predict_proba(X)[:, 1]
            adj_probs = self.rf_adj.predict_proba(X)[:, 1]

            results = {}
            for idx, key in enumerate(pair_keys):
                d_p = float(door_probs[idx])
                a_p = float(adj_probs[idx])
                results[key] = {
                    "door_prob": round(d_p, 4),
                    "adj_prob": round(a_p, 4),
                    "recommended_adjacent": a_p >= self.adj_threshold,
                    "recommended_door": d_p >= self.door_threshold,
                }
            return results

        except Exception as e:
            logger.warning(f"Error during ML inference: {e}. Utilizing heuristic fallback.")
            return self._heuristic_fallback(plot, rooms)

    def _heuristic_fallback(
        self,
        plot: PlotInput,
        rooms: List[RoomSpecification],
    ) -> Dict[Tuple[str, str], Dict[str, float]]:
        """Reliable rule-based architectural fallback when ML is inactive."""
        results = {}
        n = len(rooms)
        for i in range(n):
            for j in range(i + 1, n):
                r1 = rooms[i]
                r2 = rooms[j]
                cats = {r1.category, r2.category}
                key = (r1.id, r2.id)

                # Standard architectural rules
                if cats == {"bedroom", "bathroom"}:
                    adj_p, door_p = 0.85, 0.75
                elif cats == {"living", "kitchen"}:
                    adj_p, door_p = 0.80, 0.65
                elif cats == {"living", "bedroom"}:
                    adj_p, door_p = 0.50, 0.40
                elif cats == {"living", "parking"}:
                    adj_p, door_p = 0.70, 0.60
                elif cats == {"bedroom", "bedroom"}:
                    adj_p, door_p = 0.45, 0.10  # Bedrooms share walls but rarely doors
                elif cats == {"kitchen", "bathroom"}:
                    adj_p, door_p = 0.30, 0.05
                else:
                    adj_p, door_p = 0.35, 0.20

                results[key] = {
                    "door_prob": adj_p,
                    "adj_prob": door_p,
                    "recommended_adjacent": adj_p >= 0.50,
                    "recommended_door": door_p >= 0.40,
                }
        return results
