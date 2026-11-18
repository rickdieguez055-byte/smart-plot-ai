"""Tests for PlotInput, LayoutRequirements, and Pydantic validation (SP-AI-01, SP-AI-03, SP-AI-04)."""
import pytest
from pydantic import ValidationError
from backend.app.schemas.plot import OrientationEnum, PlotInput, PlotUnit
from backend.app.schemas.layout import LayoutRequirements, PlanGenerateRequest


def test_valid_plot_input():
    plot = PlotInput(
        plot_length=50.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="North",
    )
    assert plot.plot_length == 50.0
    assert plot.plot_width == 25.0
    assert plot.front_width == 25.0
    assert plot.entrance_orientation == OrientationEnum.NORTH
    assert plot.unit == PlotUnit.FEET


def test_orientation_normalization():
    p1 = PlotInput(plot_length=45.0, plot_width=25.0, front_width=25.0, entrance_orientation="south")
    assert p1.entrance_orientation == OrientationEnum.SOUTH

    p2 = PlotInput(plot_length=45.0, plot_width=25.0, front_width=25.0, entrance_orientation="NORTH_EAST")
    assert p2.entrance_orientation == OrientationEnum.NORTH_EAST

    p3 = PlotInput(plot_length=45.0, plot_width=25.0, front_width=25.0, entrance_orientation="sw")
    assert p3.entrance_orientation == OrientationEnum.SOUTH_WEST


def test_zero_or_negative_plot_length():
    with pytest.raises(ValidationError) as exc:
        PlotInput(plot_length=0.0, plot_width=25.0, front_width=25.0, entrance_orientation="North")
    assert "plot_length" in str(exc.value)

    with pytest.raises(ValidationError) as exc2:
        PlotInput(plot_length=-10.0, plot_width=25.0, front_width=25.0, entrance_orientation="North")
    assert "plot_length" in str(exc2.value)


def test_zero_or_negative_plot_width():
    with pytest.raises(ValidationError) as exc:
        PlotInput(plot_length=50.0, plot_width=-5.0, front_width=25.0, entrance_orientation="North")
    assert "plot_width" in str(exc.value)


def test_invalid_entrance_orientation():
    with pytest.raises(ValidationError) as exc:
        PlotInput(plot_length=50.0, plot_width=25.0, front_width=25.0, entrance_orientation="Upward")
    assert "entrance_orientation" in str(exc.value)


def test_front_width_excessive_violation():
    with pytest.raises(ValidationError) as exc:
        PlotInput(plot_length=50.0, plot_width=25.0, front_width=120.0, entrance_orientation="North")
    assert "Front width" in str(exc.value)


def test_layout_requirements_defaults():
    req = LayoutRequirements()
    assert req.bedrooms == 2
    assert req.bathrooms == 2
    assert req.kitchen is True
    assert req.living_room is True
    assert req.parking is True


def test_layout_requirements_invalid_bedrooms():
    with pytest.raises(ValidationError):
        LayoutRequirements(bedrooms=0)
    with pytest.raises(ValidationError):
        LayoutRequirements(bedrooms=10)


def test_layout_requirements_multi_floor_supported():
    """Verify that multi-floor (floors=2) is supported in Phase 6, while floors > 2 is rejected."""
    valid_req = LayoutRequirements(floors=2)
    assert valid_req.floors == 2

    with pytest.raises(ValidationError) as exc_info:
        LayoutRequirements(floors=3)
    assert "less than or equal to 2" in str(exc_info.value) or "Multi-floor generation" in str(exc_info.value)

