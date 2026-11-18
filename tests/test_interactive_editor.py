"""Tests for Interactive Floor Plan Editing Engine (Phase 7)."""
import pytest
from starlette.testclient import TestClient

from backend.app.engine.interactive_editor import InteractivePlanEditor
from backend.app.main import app
from backend.app.schemas.edit import PlanEditValidationRequest, RoomEditInput
from backend.app.schemas.plot import PlotInput

client = TestClient(app)


@pytest.fixture
def base_25x45_plot():
    return PlotInput(
        plot_length=45.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation="South",
        unit="feet",
    )


@pytest.fixture
def valid_ground_floor_rooms():
    return [
        RoomEditInput(id="porch_gf", name="Car Porch & Parking", category="parking", x=0.0, y=0.0, width=11.5, length=14.4, floor=1),
        RoomEditInput(id="stair_gf", name="Staircase Core", category="staircase", x=0.0, y=14.4, width=6.5, length=11.5, floor=1),
        RoomEditInput(id="drawing_gf", name="Drawing Room / Baithak", category="drawing", x=11.5, y=0.0, width=13.5, length=14.4, floor=1),
        RoomEditInput(id="living_gf", name="Living Room & Dining", category="living", x=6.5, y=14.4, width=18.5, length=15.6, floor=1),
        RoomEditInput(id="kitchen_gf", name="Kitchen", category="kitchen", x=0.0, y=25.9, width=6.5, length=9.1, floor=1),
        RoomEditInput(id="bed_gf", name="Master Bedroom", category="bedroom", x=0.0, y=35.0, width=13.5, length=10.0, floor=1),
        RoomEditInput(id="bath_gf", name="Attached Bath", category="bathroom", x=13.5, y=35.0, width=11.5, length=10.0, floor=1),
    ]


@pytest.fixture
def valid_first_floor_rooms():
    return [
        RoomEditInput(id="terrace_f1", name="Front Open Terrace", category="terrace", x=0.0, y=0.0, width=11.5, length=11.7, floor=2),
        RoomEditInput(id="stair_f1", name="Staircase Core", category="staircase", x=0.0, y=14.4, width=6.5, length=11.5, floor=2),
        RoomEditInput(id="lounge_f1", name="Upper Family Lounge", category="living", x=6.5, y=14.4, width=18.5, length=15.6, floor=2),
        RoomEditInput(id="bed1_f1", name="Family Bedroom 1", category="bedroom", x=0.0, y=25.9, width=12.5, length=9.1, floor=2),
        RoomEditInput(id="bath1_f1", name="Attached Bath 1", category="bathroom", x=12.5, y=25.9, width=12.5, length=9.1, floor=2),
        RoomEditInput(id="bed2_f1", name="Family Bedroom 2", category="bedroom", x=0.0, y=35.0, width=13.5, length=10.0, floor=2),
        RoomEditInput(id="bath2_f1", name="Attached Bath 2", category="bathroom", x=13.5, y=35.0, width=11.5, length=10.0, floor=2),
    ]


def test_valid_room_move(base_25x45_plot, valid_ground_floor_rooms):
    """Test moving a room within legal bounds succeeds and regenerates layout elements."""
    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=valid_ground_floor_rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is True
    assert res.error_code is None
    assert res.recalculated_layout is not None
    assert len(res.recalculated_layout.rooms) == 7
    assert len(res.recalculated_layout.doors) > 0
    assert len(res.recalculated_layout.windows) > 0
    assert "<svg" in res.recalculated_layout.svg_floor_plan


def test_valid_room_resize(base_25x45_plot, valid_ground_floor_rooms):
    """Test resizing a bedroom within allowable boundary updates dimensions and area."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    # Resize bed_gf from 13.5x10.0 to 12.0x10.0 and shift attached bath to maintain shared wall
    bed = next(r for r in rooms if r.id == "bed_gf")
    bed.width = 12.0
    bath = next(r for r in rooms if r.id == "bath_gf")
    bath.x = 12.0
    bath.width = 13.0

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is True
    recalc_bed = next(r for r in res.recalculated_layout.rooms if r.id == "bed_gf")
    assert recalc_bed.width == 12.0
    assert recalc_bed.area == 120.0
    recalc_bath = next(r for r in res.recalculated_layout.rooms if r.id == "bath_gf")
    assert recalc_bath.x == 12.0
    assert recalc_bath.width == 13.0


def test_out_of_bounds_negative_coordinates(base_25x45_plot, valid_ground_floor_rooms):
    """Moving a room to negative coordinates must be rejected with OUT_OF_BOUNDS."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    rooms[0].x = -5.0  # Illegal negative X

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "OUT_OF_BOUNDS"
    assert "Car Porch & Parking" in res.rejection_reason
    assert "porch_gf" in res.conflicting_room_ids


def test_out_of_bounds_exceeding_width(base_25x45_plot, valid_ground_floor_rooms):
    """Moving or resizing a room beyond plot width must be rejected with OUT_OF_BOUNDS."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    # Drawing room placed at x=15 with width=15 -> right edge=30 > 25 ft plot width
    draw = next(r for r in rooms if r.id == "drawing_gf")
    draw.x = 15.0
    draw.width = 15.0

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "OUT_OF_BOUNDS"
    assert "width" in res.rejection_reason.lower()


def test_out_of_bounds_exceeding_length(base_25x45_plot, valid_ground_floor_rooms):
    """Moving or resizing a room beyond plot length must be rejected with OUT_OF_BOUNDS."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    # Master bedroom placed at y=40 with length=10 -> top edge=50 > 45 ft plot length
    bed = next(r for r in rooms if r.id == "bed_gf")
    bed.y = 40.0
    bed.length = 10.0

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "OUT_OF_BOUNDS"
    assert "length" in res.rejection_reason.lower()


def test_room_overlap_detected(base_25x45_plot, valid_ground_floor_rooms):
    """Rooms colliding/overlapping must be rejected with ROOM_OVERLAP."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    # Move drawing room to collide with porch
    draw = next(r for r in rooms if r.id == "drawing_gf")
    draw.x = 2.0  # Collides with porch at x=0..11.5, y=0..14.4

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "ROOM_OVERLAP"
    assert "porch_gf" in res.conflicting_room_ids
    assert "drawing_gf" in res.conflicting_room_ids
    assert "overlap" in res.rejection_reason.lower()


def test_minimum_dimension_violation_width(base_25x45_plot, valid_ground_floor_rooms):
    """Shrinking a bedroom width below architectural standards must be rejected."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    bed = next(r for r in rooms if r.id == "bed_gf")
    bed.width = 6.0  # Bedroom width < 9.0 ft minimum

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "MIN_DIMENSION_VIOLATION"
    assert "Master Bedroom" in res.rejection_reason


def test_minimum_dimension_violation_area(base_25x45_plot, valid_ground_floor_rooms):
    """Shrinking a room below minimum area must be rejected."""
    rooms = [r.model_copy() for r in valid_ground_floor_rooms]
    kitchen = next(r for r in rooms if r.id == "kitchen_gf")
    kitchen.width = 6.0
    kitchen.length = 6.0  # 36 sq ft < 45 sq ft minimum

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=1,
        rooms=rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "MIN_DIMENSION_VIOLATION"
    assert "Kitchen" in res.rejection_reason


def test_staircase_misalignment_between_floors(base_25x45_plot, valid_first_floor_rooms, valid_ground_floor_rooms):
    """Moving staircase on First Floor away from Ground Floor shaft must be rejected."""
    f1_rooms = [r.model_copy() for r in valid_first_floor_rooms]
    stair_f1 = next(r for r in f1_rooms if r.id == "stair_f1")
    # Shift staircase by 2.0 ft horizontally
    stair_f1.x = 2.0

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=2,
        floors_count=2,
        rooms=f1_rooms,
        other_floor_rooms=valid_ground_floor_rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code == "STAIRCASE_MISALIGNMENT"
    assert "staircase" in res.rejection_reason.lower()


def test_vertical_conflict_obstructing_staircase(base_25x45_plot, valid_first_floor_rooms, valid_ground_floor_rooms):
    """Placing a room over the counterpart floor's staircase shaft must be rejected."""
    # On ground floor, delete stair_gf and place a store over the staircase zone
    gf_rooms = [r for r in valid_ground_floor_rooms if r.id != "stair_gf"]
    gf_rooms.append(RoomEditInput(id="store_gf", name="Luggage Store", category="utility", x=0.0, y=14.4, width=6.5, length=11.5, floor=1))

    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=2,
        rooms=gf_rooms,
        other_floor_rooms=valid_first_floor_rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is False
    assert res.error_code in ["STAIRCASE_MISSING", "VERTICAL_CONFLICT"]


def test_mathematical_conservation_on_edited_layout(base_25x45_plot, valid_ground_floor_rooms):
    """Edited layout must satisfy exact mathematical conservation invariant."""
    req = PlanEditValidationRequest(
        plot=base_25x45_plot,
        floor=1,
        floors_count=2,
        rooms=valid_ground_floor_rooms,
    )
    res = InteractivePlanEditor.validate_and_apply_edit(req)
    assert res.is_valid is True
    sb = res.recalculated_layout.spatial_breakdown
    assert sb.conservation_verified is True
    assert sb.conservation_discrepancy <= 0.05
    assert sb.total_covered_area <= (25.0 * 45.0 * 2.0)


def test_api_validate_edit_endpoint(base_25x45_plot, valid_ground_floor_rooms):
    """Test POST /api/v1/plans/validate-edit endpoint with valid payload."""
    payload = {
        "plot": base_25x45_plot.model_dump(),
        "floor": 1,
        "floors_count": 1,
        "rooms": [r.model_dump() for r in valid_ground_floor_rooms],
    }
    response = client.post("/api/v1/plans/validate-edit", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["is_valid"] is True
    assert data["recalculated_layout"] is not None


def test_api_apply_edit_endpoint_invalid_payload(base_25x45_plot, valid_ground_floor_rooms):
    """Test POST /api/v1/plans/apply-edit returns rejection reason for invalid edit."""
    rooms = [r.model_dump() for r in valid_ground_floor_rooms]
    rooms[0]["x"] = -10.0  # Invalid negative coordinate

    payload = {
        "plot": base_25x45_plot.model_dump(),
        "floor": 1,
        "floors_count": 1,
        "rooms": rooms,
    }
    response = client.post("/api/v1/plans/apply-edit", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["is_valid"] is False
    assert data["error_code"] == "OUT_OF_BOUNDS"
    assert "Car Porch & Parking" in data["rejection_reason"]
