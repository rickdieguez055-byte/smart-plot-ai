"""Feature extraction for architectural room-pair relationship prediction.

Strictly avoids target leakage: only utilizes features available prior to spatial placement
(plot boundary envelope, room requirements, room categories, and relative area targets).
"""
import math
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Set, Tuple

import pandas as pd

from backend.app.ml.taxonomy import CANONICAL_CATEGORIES, map_room_label


@dataclass
class RoomEntity:
    id: str
    raw_label: str
    category: str
    area: float
    polygon: Optional[List[List[float]]] = None
    walls: Optional[List[str]] = None


@dataclass
class FloorPlanGraph:
    plan_id: str
    bounding_width: float
    bounding_length: float
    total_area: float
    rooms: List[RoomEntity]
    adjacencies: Set[Tuple[int, int]]  # Indices in rooms list
    door_connections: Set[Tuple[int, int]]


def extract_pair_features(
    r1: RoomEntity,
    r2: RoomEntity,
    total_rooms: int,
    plot_width: float,
    plot_length: float,
    total_area: float,
    room_counts: Dict[str, int],
) -> Dict[str, Any]:
    """Computes leakage-free pairwise features for a pair of rooms in a plan."""
    # Ensure canonical ordering of categories for symmetric pair representations
    cat1, cat2 = sorted([r1.category, r2.category])
    pair_type = f"{cat1}_{cat2}"

    area1 = max(1.0, r1.area)
    area2 = max(1.0, r2.area)
    tot_area = max(10.0, total_area)

    plot_w = max(1.0, plot_width)
    plot_l = max(1.0, plot_length)
    plot_aspect = round(max(plot_w, plot_l) / min(plot_w, plot_l), 3)

    return {
        "plot_width": round(plot_w, 2),
        "plot_length": round(plot_l, 2),
        "plot_area": round(tot_area, 2),
        "plot_aspect_ratio": plot_aspect,
        "total_rooms": total_rooms,
        "num_bedrooms": room_counts.get("bedroom", 0),
        "num_bathrooms": room_counts.get("bathroom", 0),
        "has_living": 1 if room_counts.get("living", 0) > 0 else 0,
        "has_kitchen": 1 if room_counts.get("kitchen", 0) > 0 else 0,
        "has_parking": 1 if room_counts.get("parking", 0) > 0 else 0,
        "room1_category": cat1,
        "room2_category": cat2,
        "pair_type": pair_type,
        "is_same_category": 1 if cat1 == cat2 else 0,
        "room1_area_ratio": round(min(area1, area2) / tot_area, 4),
        "room2_area_ratio": round(max(area1, area2) / tot_area, 4),
        "pair_area_ratio": round(min(area1, area2) / max(area1, area2), 4),
    }
