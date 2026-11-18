"""Interactive Floor Plan Editing Request and Response schemas for SmartPlot AI Phase 7."""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

from backend.app.schemas.plot import PlotInput
from backend.app.schemas.response import FloorLayoutOutput, RoomOutput


class RoomEditInput(BaseModel):
    """Geometry specification for a single editable room."""
    id: str = Field(..., description="Unique room identifier (e.g. master_bed_gf)")
    name: str = Field(..., description="Readable room label (e.g. Master Bedroom)")
    category: str = Field(..., description="Room category (bedroom, bathroom, kitchen, living, parking, staircase, terrace, utility)")
    x: float = Field(..., description="Bottom-left X coordinate in feet")
    y: float = Field(..., description="Bottom-left Y coordinate in feet")
    width: float = Field(..., description="Room width along X axis in feet")
    length: float = Field(..., description="Room length/depth along Y axis in feet")
    floor: int = Field(default=1, description="Floor level (1 for Ground Floor, 2 for First Floor)")

    @property
    def area(self) -> float:
        return round(self.width * self.length, 2)


class PlanEditValidationRequest(BaseModel):
    """Request payload for validating and recalculating an edited floor plan layout."""
    plot: PlotInput = Field(..., description="Plot dimensions, setbacks, and orientation")
    floor: int = Field(default=1, ge=1, le=2, description="Floor level being edited (1 for GF, 2 for 1F)")
    floors_count: int = Field(default=1, ge=1, le=2, description="Total number of floors in residence")
    rooms: List[RoomEditInput] = Field(..., description="Complete set of edited rooms for the active floor")
    other_floor_rooms: Optional[List[RoomEditInput]] = Field(
        default=None, description="Rooms on the counterpart floor for cross-floor vertical/staircase alignment checks"
    )
    circulation_paths: Optional[List[Dict[str, Any]]] = Field(
        default=None, description="Optional custom or preserved circulation paths"
    )
    original_plan_id: Optional[str] = Field(default=None, description="Reference ID of the original AI plan")
    alternative_type: Optional[str] = Field(default="open_living", description="Layout archetype ('open_living' or 'privacy_focused')")
    plan_title: Optional[str] = Field(default=None, description="Custom plan title")


class PlanEditValidationResponse(BaseModel):
    """Response returned after validating an edited floor plan."""
    status: str = Field(default="success", description="'success' or 'error'")
    is_valid: bool = Field(..., description="True if geometry passes all architectural checks")
    error_code: Optional[str] = Field(
        default=None,
        description="Error code if invalid: OUT_OF_BOUNDS, ROOM_OVERLAP, MIN_DIMENSION_VIOLATION, "
                    "STAIRCASE_MISALIGNMENT, CIRCULATION_BLOCKED, AREA_EXCEEDED"
    )
    rejection_reason: Optional[str] = Field(
        default=None, description="Clear, human-readable architectural explanation for rejection"
    )
    conflicting_room_ids: List[str] = Field(
        default_factory=list, description="IDs of rooms involved in collisions or violations"
    )
    recalculated_layout: Optional[FloorLayoutOutput] = Field(
        default=None, description="Recalculated layout with updated walls, doors, windows, and fresh SVG if valid"
    )
    multi_floor_validation: Optional[Dict[str, Any]] = Field(
        default=None, description="Multi-floor vertical stack and staircase coordination details"
    )
    is_ml_recommended: bool = Field(
        default=False, description="Whether this edit configuration was suggested by the ML affinity model"
    )
    recommendations: List[str] = Field(
        default_factory=list, description="Architectural guidance notes for optimizing the edited layout"
    )
