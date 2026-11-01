"""Phase 2 Automated Tests: Floor Plan Quality, Connectivity, Doors, Windows, and Dual Alternatives."""
import pytest
from fastapi.testclient import TestClient

from backend.app.engine.architectural_rules import (
    MIN_CORRIDOR_WIDTH,
    verify_floor_plan_reachability,
)
from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.main import app
from backend.app.schemas.layout import LayoutRequirements, PlanGenerateRequest
from backend.app.schemas.plot import OrientationEnum, PlotInput

client = TestClient(app)


# -----------------------------------------------------------------------------
# 1. MULTI-PLAN DIVERSITY & ALTERNATIVES
# -----------------------------------------------------------------------------
def test_dual_plan_alternatives_generated():
    payload = {
        "plot": {
            "plot_length": 45.0,
            "plot_width": 25.0,
            "front_width": 25.0,
            "entrance_orientation": "South",
            "unit": "feet",
        },
        "requirements": {
            "bedrooms": 2,
            "bathrooms": 2,
            "kitchen": True,
            "living_room": True,
            "parking": True,
        },
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert "alternatives" in data
    assert len(data["alternatives"]) == 2

    plan_a = data["alternatives"][0]
    plan_b = data["alternatives"][1]

    assert plan_a["layout_type"] == "open_living"
    assert plan_b["layout_type"] == "privacy_focused"
    assert "Open Living" in plan_a["title"]
    assert "Privacy Focused" in plan_b["title"]

    # Verify meaningful geometric & topological diversity
    # Plan B contains Formal Drawing Room, Plan A contains Open Living
    plan_a_names = [r["name"] for r in plan_a["rooms"]]
    plan_b_names = [r["name"] for r in plan_b["rooms"]]

    assert any("Open" in name or "Living" in name for name in plan_a_names)
    assert any("Formal Drawing Room" in name for name in plan_b_names)

    # Coordinates must differ between alternatives
    assert plan_a["rooms"] != plan_b["rooms"]


# -----------------------------------------------------------------------------
# 2. ROOM CONNECTIVITY & DOOR ACCESSIBILITY
# -----------------------------------------------------------------------------
def test_room_connectivity_and_door_accessibility():
    plot = PlotInput(
        plot_length=50.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="South",
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2)
    alternatives = SpatialLayoutSolver.solve_alternatives(plot, req)

    for alt in alternatives:
        assert alt.connectivity_verified is True
        assert len(alt.doors) >= len(alt.rooms)  # At least one door per room + main entrance

        # Run direct BFS verification
        graph_res = verify_floor_plan_reachability(
            rooms=[r.model_dump() for r in alt.rooms],
            circulation_paths=[cp.model_dump() for cp in alt.circulation_paths],
            doors=[d.model_dump() for d in alt.doors],
            entrance_foyer_id="foyer",
        )
        assert graph_res.is_valid is True, f"{alt.title} failed reachability: {graph_res.error_message}"
        assert len(graph_res.unreachable_rooms) == 0
        assert len(graph_res.privacy_violations) == 0


# -----------------------------------------------------------------------------
# 3. ENTRANCE POSITION & PARKING CONNECTION
# -----------------------------------------------------------------------------
def test_valid_entrance_position_and_parking_connection():
    plot = PlotInput(
        plot_length=45.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="South",
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2, parking=True)
    alternatives = SpatialLayoutSolver.solve_alternatives(plot, req)

    for alt in alternatives:
        # 1. Check parking touches front entrance boundary (y = 0)
        porch = next((r for r in alt.rooms if r.category == "parking"), None)
        assert porch is not None
        assert porch.y == 0.0, f"Parking does not connect to front road boundary in {alt.title}"

        # 2. Check main exterior door is present at the front boundary
        ext_doors = [d for d in alt.doors if d.is_exterior]
        assert len(ext_doors) >= 1
        assert any(d.y <= 0.1 for d in ext_doors), f"Main exterior entrance door missing in {alt.title}"


# -----------------------------------------------------------------------------
# 4. CORRIDOR WIDTH CONSTRAINTS
# -----------------------------------------------------------------------------
def test_corridor_width_constraints():
    plot = PlotInput(
        plot_length=50.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="South",
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2)
    alternatives = SpatialLayoutSolver.solve_alternatives(plot, req)

    for alt in alternatives:
        assert len(alt.circulation_paths) >= 1
        for cp in alt.circulation_paths:
            # Corridor width must meet architectural minimum (3.5 ft)
            min_dim = min(cp.width, cp.length)
            assert min_dim >= MIN_CORRIDOR_WIDTH - 0.1, (
                f"Corridor '{cp.name}' width ({min_dim:.1f} ft) violates minimum standard ({MIN_CORRIDOR_WIDTH} ft)"
            )


# -----------------------------------------------------------------------------
# 5. WINDOW EXTERIOR WALL CHECKS
# -----------------------------------------------------------------------------
def test_window_exterior_access():
    plot = PlotInput(
        plot_length=45.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="South",
    )
    req = LayoutRequirements(bedrooms=2, bathrooms=2)
    alternatives = SpatialLayoutSolver.solve_alternatives(plot, req)

    for alt in alternatives:
        assert len(alt.windows) >= 3  # At least Living, Bedrooms, Kitchen

        for win in alt.windows:
            # Verify window coordinates sit on the outer plot perimeter
            on_south = win.y <= 0.8
            on_north = win.y >= 45.0 - 0.8
            on_west = win.x <= 0.8
            on_east = win.x >= 25.0 - 0.8

            assert on_south or on_north or on_west or on_east, (
                f"Window {win.id} at ({win.x}, {win.y}) is not on an exterior wall in {alt.title}"
            )


# -----------------------------------------------------------------------------
# 6. SPATIAL CALCULATION ACCURACY & AREA ACCOUNTING
# -----------------------------------------------------------------------------
def test_spatial_calculation_accuracy():
    payload = {
        "plot": {
            "plot_length": 45.0,
            "plot_width": 25.0,
            "front_width": 25.0,
            "entrance_orientation": "South",
            "unit": "feet",
        },
        "requirements": {
            "bedrooms": 2,
            "bathrooms": 2,
        },
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 200
    data = response.json()

    sb = data["spatial_breakdown"]
    assert sb is not None

    plot_area = sb["total_plot_area"]
    assert plot_area == 45.0 * 25.0

    # Ensure net room area, circulation, and walls are calculated separately
    assert sb["net_room_area"] > 0
    assert sb["circulation_area"] > 0
    assert sb["wall_area"] > 0

    # Total covered footprint
    expected_covered = round(sb["net_room_area"] + sb["circulation_area"] + sb["wall_area"], 2)
    assert abs(sb["total_covered_area"] - expected_covered) < 0.1

    # Total plot equals covered + open + setback
    sum_areas = round(sb["total_covered_area"] + sb["open_unallocated_area"] + sb["setback_area"], 2)
    assert abs(sum_areas - plot_area) < 0.5


# -----------------------------------------------------------------------------
# 7. ARCHITECTURAL SVG ELEMENTS (DOORS, WINDOWS, WALLS)
# -----------------------------------------------------------------------------
def test_architectural_svg_rendering():
    payload = {
        "plot": {
            "plot_length": 45.0,
            "plot_width": 25.0,
            "front_width": 25.0,
            "entrance_orientation": "South",
        },
        "requirements": {
            "bedrooms": 2,
            "bathrooms": 2,
        },
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 200
    data = response.json()

    for alt in data["alternatives"]:
        svg = alt["svg_floor_plan"]
        assert "<svg" in svg
        assert "</svg>" in svg

        # Check door swing arc
        assert 'stroke-dasharray="2,2"' in svg  # door swing arc

        # Check window styling (blue sill lines)
        assert 'stroke="#0284C7"' in svg

        # Check corridor pattern
        assert "corridor_pattern" in svg

        # Check disclaimer notice (SP-AI-10)
        assert "MANDATORY PRELIMINARY NOTICE" in svg
