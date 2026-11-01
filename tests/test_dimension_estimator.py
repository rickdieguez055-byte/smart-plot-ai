"""Tests for DimensionEstimator and feasibility analysis."""
import pytest
from backend.app.core.errors import SpatialInfeasibilityException
from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import PlotInput, PlotUnit


def test_standard_5_marla_plot_estimation():
    plot = PlotInput(
        plot_length=45.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="North",
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2)
    rooms, metrics = DimensionEstimator.estimate_rooms(plot, req)

    assert len(rooms) >= 6  # parking, living, kitchen, 2 beds, 2 baths
    assert metrics["buildable_area"] == 45.0 * 25.0
    assert metrics["scale_factor"] == 0.90  # compact scale for 1125 sq ft

    # Verify room targets are positive
    for r in rooms:
        assert r.target_width > 0
        assert r.target_length > 0
        assert r.min_width <= r.target_width <= r.max_width


def test_meters_unit_conversion():
    plot = PlotInput(
        plot_length=15.0,  # ~49 ft
        plot_width=8.0,    # ~26 ft
        front_width=8.0,
        entrance_orientation="East",
        unit=PlotUnit.METERS,
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=1)
    rooms, metrics = DimensionEstimator.estimate_rooms(plot, req)
    assert len(rooms) > 0
    assert metrics["buildable_width"] == 8.0
    assert metrics["buildable_length"] == 15.0


def test_impossible_room_requirements_raises_infeasibility():
    """Requesting 6 bedrooms, 5 bathrooms, kitchen, dining on a tiny 20x20 plot must fail."""
    plot = PlotInput(
        plot_length=20.0,
        plot_width=20.0,
        front_width=20.0,
        entrance_orientation="South",
    )
    req = LayoutRequirements(
        bedrooms=6,
        bathrooms=5,
        kitchen=True,
        living_room=True,
        dining_room=True,
        parking=True,
    )
    with pytest.raises(SpatialInfeasibilityException) as exc:
        DimensionEstimator.estimate_rooms(plot, req)

    assert "Requested rooms require at least" in str(exc.value.message)
    assert exc.value.code == "SPATIAL_INFEASIBILITY"
    assert "deficit" in exc.value.details
