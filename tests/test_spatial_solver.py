"""Tests for Google OR-Tools CP-SAT and Geometric Spatial Solver."""
import pytest
from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import OrientationEnum, PlotInput


def check_no_overlap(rooms, tolerance=0.05):
    """Verifies that no two room rectangles intersect in 2D space."""
    for i in range(len(rooms)):
        for j in range(i + 1, len(rooms)):
            r1 = rooms[i]
            r2 = rooms[j]

            # Horizontal overlap condition
            no_x_overlap = (r1.x + r1.width <= r2.x + tolerance) or (r2.x + r2.width <= r1.x + tolerance)
            # Vertical overlap condition
            no_y_overlap = (r1.y + r1.length <= r2.y + tolerance) or (r2.y + r2.length <= r1.y + tolerance)

            overlap = not (no_x_overlap or no_y_overlap)
            assert not overlap, (
                f"Overlap detected between {r1.name} (x={r1.x}, y={r1.y}, w={r1.width}, l={r1.length}) "
                f"and {r2.name} (x={r2.x}, y={r2.y}, w={r2.width}, l={r2.length})"
            )


def check_boundary_containment(rooms, max_w, max_l, tolerance=0.1):
    """Verifies all rooms are strictly inside the buildable envelope."""
    for r in rooms:
        assert r.x >= -tolerance, f"{r.name} x is negative: {r.x}"
        assert r.y >= -tolerance, f"{r.name} y is negative: {r.y}"
        assert r.x + r.width <= max_w + tolerance, (
            f"{r.name} exceeds width: {r.x + r.width} > {max_w}"
        )
        assert r.y + r.length <= max_l + tolerance, (
            f"{r.name} exceeds length: {r.y + r.length} > {max_l}"
        )


@pytest.mark.parametrize(
    "plot_w, plot_l, beds, baths",
    [
        (25.0, 45.0, 2, 2),  # Standard 5 Marla (Peshawar / Lahore)
        (25.0, 50.0, 3, 2),  # Standard 5 Marla (Islamabad)
        (35.0, 65.0, 3, 3),  # Standard 10 Marla
        (50.0, 90.0, 4, 4),  # Standard 1 Kanal
    ],
)
def test_spatial_solver_invariants(plot_w, plot_l, beds, baths):
    plot = PlotInput(
        plot_length=plot_l,
        plot_width=plot_w,
        front_width=plot_w,
        entrance_orientation="South",
    )
    req = LayoutRequirements(bedrooms=beds, bathrooms=baths)

    rooms_specs, metrics = DimensionEstimator.estimate_rooms(plot, req)
    bw = metrics["buildable_width"]
    bl = metrics["buildable_length"]

    solved = SpatialLayoutSolver.solve(plot, rooms_specs, bw, bl)

    assert len(solved) == len(rooms_specs)
    check_boundary_containment(solved, bw, bl)
    check_no_overlap(solved)


def test_fallback_partitioner_direct():
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

    # Directly test geometric partitioner
    solved = SpatialLayoutSolver._solve_geometric_partitioning(plot, rooms_specs, bw, bl)
    assert len(solved) == len(rooms_specs)
    check_boundary_containment(solved, bw, bl)
    check_no_overlap(solved)
