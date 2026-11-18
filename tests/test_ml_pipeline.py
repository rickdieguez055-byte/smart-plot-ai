"""Unit and integration tests for Phase 5 Machine Learning pipeline."""
import os
import pytest
from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.ml.dataset import (
    build_pairwise_dataframe,
    compute_polygon_area,
    load_resplan_split,
    parse_plan_dict,
)
from backend.app.ml.features import (
    FloorPlanGraph,
    RoomEntity,
    extract_pair_features,
)
from backend.app.ml.hybrid_solver import HybridSpatialSolver
from backend.app.ml.model import RoomRelationshipPredictor
from backend.app.ml.taxonomy import CANONICAL_CATEGORIES, map_room_label
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import OrientationEnum, PlotInput, SetbackInput


def test_taxonomy_mapping():
    assert map_room_label("LIVING") == "living"
    assert map_room_label("LIVING_ROOM") == "living"
    assert map_room_label("BEDROOM") == "bedroom"
    assert map_room_label("BATH") == "bathroom"
    assert map_room_label("KITCHEN") == "kitchen"
    assert map_room_label("BALCONY") == "parking"
    assert map_room_label("UNKNOWN_ROOM") in CANONICAL_CATEGORIES


def test_compute_polygon_area_shoelace():
    # 10 x 20 rectangle
    rect = [[0.0, 0.0], [10.0, 0.0], [10.0, 20.0], [0.0, 20.0]]
    assert compute_polygon_area(rect) == 200.0

    # Degenerate polygon
    assert compute_polygon_area([[0.0, 0.0], [5.0, 5.0]]) == 0.0


def test_feature_extraction_leakage_free():
    r1 = RoomEntity(id="r1", raw_label="BEDROOM", category="bedroom", area=150.0)
    r2 = RoomEntity(id="r2", raw_label="BATH", category="bathroom", area=45.0)

    feat = extract_pair_features(
        r1=r1,
        r2=r2,
        total_rooms=5,
        plot_width=25.0,
        plot_length=45.0,
        total_area=1125.0,
        room_counts={"bedroom": 2, "bathroom": 2, "living": 1},
    )

    # Verify no coordinates or spatial outputs leaked
    assert "x" not in feat
    assert "y" not in feat
    assert "is_adjacent" not in feat
    assert "is_connected" not in feat

    # Verify correct feature types
    assert feat["plot_width"] == 25.0
    assert feat["plot_length"] == 45.0
    assert feat["plot_aspect_ratio"] == 1.8
    assert feat["pair_type"] == "bathroom_bedroom"  # canonically sorted
    assert feat["is_same_category"] == 0
    assert 0.0 < feat["pair_area_ratio"] <= 1.0


def test_dataset_loader_and_dataframe():
    val_path = os.path.join("data", "resplan", "val.jsonl")
    if not os.path.exists(val_path):
        pytest.skip("ResPlan val split not downloaded yet")

    plans = load_resplan_split(val_path, max_plans=5)
    assert len(plans) == 5
    for p in plans:
        assert len(p.rooms) >= 2
        assert p.bounding_width > 0
        assert p.bounding_length > 0
        assert p.total_area > 0

    df = build_pairwise_dataframe(plans)
    assert not df.empty
    assert "is_adjacent" in df.columns
    assert "is_connected" in df.columns
    assert set(df["is_adjacent"].unique()).issubset({0, 1})
    assert set(df["is_connected"].unique()).issubset({0, 1})


def test_predictor_fallback_behavior():
    # Use empty artifacts directory to test graceful fallback
    predictor = RoomRelationshipPredictor(artifacts_dir="non_existent_dir")
    assert predictor.is_loaded is False

    plot = PlotInput(
        plot_width=25.0,
        plot_length=45.0,
        front_width=25.0,
        entrance_orientation=OrientationEnum.NORTH,
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2, kitchen=True, living_room=True, parking=True, floors=1)
    rooms_specs, _ = DimensionEstimator.estimate_rooms(plot, req)

    predictions = predictor.predict_pair_relationship(plot, rooms_specs)
    assert len(predictions) > 0

    # Check that probabilities are bounded and reasonable
    for pair, rel in predictions.items():
        assert 0.0 <= rel["door_prob"] <= 1.0
        assert 0.0 <= rel["adj_prob"] <= 1.0
        assert isinstance(rel["recommended_adjacent"], bool)
        assert isinstance(rel["recommended_door"], bool)


def test_hybrid_solver_end_to_end():
    plot = PlotInput(
        plot_width=25.0,
        plot_length=45.0,
        front_width=25.0,
        entrance_orientation=OrientationEnum.NORTH,
        setbacks=SetbackInput(front=5.0, rear=3.0, left=0.0, right=0.0),
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2, kitchen=True, living_room=True, parking=True, floors=1)

    plans = HybridSpatialSolver.solve_alternatives(plot, req, timeout_seconds=5.0)
    assert len(plans) == 2

    for plan in plans:
        assert plan.is_feasible is True
        assert plan.connectivity_verified is True
        assert len(plan.rooms) >= 6
        assert len(plan.doors) > 0
        assert len(plan.windows) > 0
        assert plan.spatial_breakdown.utilization_percentage > 50.0
