"""Tests for ML V2 loading, fallback mechanics, and generation mode recording."""
from unittest.mock import patch
import pytest
from backend.app.ml.hybrid_solver import HybridSpatialSolver
from backend.app.ml.model import RoomRelationshipPredictor
from backend.app.schemas.layout import LayoutRequirements, PlanGenerateRequest
from backend.app.schemas.plot import OrientationEnum, PlotInput, PlotUnit, SetbackInput
from backend.app.services.plan_service import PlanGenerationService


@pytest.fixture
def sample_plot():
    return PlotInput(
        plot_length=50.0,
        plot_width=25.0,
        front_width=25.0,
        unit=PlotUnit.FEET,
        entrance_orientation=OrientationEnum.NORTH,
        setbacks=SetbackInput(front=5.0, rear=4.0, left=0.0, right=0.0),
    )


@pytest.fixture
def sample_requirements():
    return LayoutRequirements(
        bedrooms=3,
        bathrooms=2,
        kitchen=True,
        living_room=True,
        parking=True,
    )


def test_ml_v2_model_loading():
    predictor = RoomRelationshipPredictor.get_instance()
    assert predictor.is_loaded is True
    assert predictor.model_version in ("v2", "v1")
    assert predictor.rf_door is not None
    assert predictor.rf_adj is not None
    assert predictor.preprocessor is not None
    assert 0.20 <= predictor.door_threshold <= 0.60
    assert 0.20 <= predictor.adj_threshold <= 0.60


def test_normal_generation_mode_is_ml_hybrid(sample_plot, sample_requirements):
    req = PlanGenerateRequest(plot=sample_plot, requirements=sample_requirements)
    resp = PlanGenerationService.generate_plan(req)

    assert resp.status == "success"
    assert len(resp.alternatives) >= 2
    assert resp.alternatives[0].generation_mode == "ml_hybrid"
    assert resp.alternatives[0].fallback_reason is None
    assert resp.metadata.get("generation_mode") == "ml_hybrid"
    assert resp.metadata.get("fallback_reason") is None


def test_graceful_fallback_on_ml_failure(sample_plot, sample_requirements):
    req = PlanGenerateRequest(plot=sample_plot, requirements=sample_requirements)

    with patch.object(
        RoomRelationshipPredictor,
        "predict_pair_relationship",
        side_effect=RuntimeError("Simulated CUDA/CPU out-of-memory or model corruption"),
    ):
        resp = PlanGenerationService.generate_plan(req)

        assert resp.status == "success"
        assert len(resp.alternatives) >= 2
        for alt in resp.alternatives:
            assert alt.generation_mode == "baseline_fallback"
            assert alt.fallback_reason is not None
            assert "Simulated CUDA/CPU" in alt.fallback_reason
            assert alt.is_feasible is True
            assert alt.connectivity_verified is True

        assert resp.metadata.get("generation_mode") == "baseline_fallback"
        assert "Simulated CUDA/CPU" in resp.metadata.get("fallback_reason", "")


def test_heuristic_fallback_when_unloaded(sample_plot, sample_requirements):
    predictor = RoomRelationshipPredictor(artifacts_dir="non_existent_directory_path")
    assert predictor.is_loaded is False
    assert predictor.model_version == "heuristic_fallback"

    from backend.app.engine.dimension_estimator import DimensionEstimator

    rooms_specs, _ = DimensionEstimator.estimate_rooms(sample_plot, sample_requirements)
    results = predictor.predict_pair_relationship(sample_plot, rooms_specs)
    assert len(results) > 0
    for key, val in results.items():
        assert "door_prob" in val
        assert "adj_prob" in val
        assert 0.0 <= val["door_prob"] <= 1.0
