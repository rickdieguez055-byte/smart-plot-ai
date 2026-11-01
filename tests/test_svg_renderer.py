"""Tests for 2D SVG Floor Plan Renderer per SP-AI-07 and SP-AI-10."""
from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.renderer.svg_renderer import SVGFloorPlanRenderer
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import PlotInput
from backend.app.schemas.response import MANDATORY_DISCLAIMER


def test_svg_rendering_elements():
    plot = PlotInput(
        plot_length=45.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="North",
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2)
    rooms_specs, metrics = DimensionEstimator.estimate_rooms(plot, req)
    bw = metrics["buildable_width"]
    bl = metrics["buildable_length"]

    rooms = SpatialLayoutSolver.solve(plot, rooms_specs, bw, bl)
    total_built = sum(r.area for r in rooms)
    utilization = (total_built / metrics["total_plot_area"]) * 100

    svg = SVGFloorPlanRenderer.render(plot, rooms, total_built, utilization)

    # Basic SVG syntax validation
    assert svg.startswith("<svg")
    assert svg.endswith("</svg>")
    assert 'viewBox="' in svg

    # Labels and dimensions
    assert "SmartPlot — 2D Architectural Layout" in svg
    assert "Master Bedroom" in svg
    assert "Car Porch &amp; Parking" in svg or "Car Porch & Parking" in svg
    assert "MAIN ACCESS ROAD / ENTRANCE" in svg or "ENTRANCE" in svg

    # Mandatory preliminary disclaimer check (SP-AI-10)
    assert "MANDATORY PRELIMINARY NOTICE" in svg
    assert "preliminary" in svg
    assert "licensed architect" in svg
