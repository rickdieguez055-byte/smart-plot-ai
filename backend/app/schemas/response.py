"""Response models for layout generation per SP-AI-07, SP-AI-08, SP-AI-10."""
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

MANDATORY_DISCLAIMER = (
    "NOTICE: This layout is a preliminary, AI-assisted conceptual design and does "
    "not constitute a certified architectural or structural engineering drawing. "
    "It must be reviewed and certified by a licensed architect or structural "
    "engineer prior to construction or municipal submission."
)


class RoomOutput(BaseModel):
    id: str = Field(..., description="Unique room identifier within plan")
    name: str = Field(..., description="Readable room label (e.g., Master Bedroom, Living Room)")
    category: str = Field(..., description="Room category (bedroom, bathroom, kitchen, living, parking, utility)")
    x: float = Field(..., description="X-coordinate of bottom-left origin in plot coordinate system")
    y: float = Field(..., description="Y-coordinate of bottom-left origin in plot coordinate system")
    width: float = Field(..., description="Room width along X axis")
    length: float = Field(..., description="Room length/depth along Y axis")
    area: float = Field(..., description="Room area (width * length)")
    floor: int = Field(default=1, description="Floor level (1 for Ground Floor)")


class DoorOutput(BaseModel):
    id: str = Field(..., description="Unique door identifier")
    from_room: str = Field(..., description="Origin room ID or 'exterior'")
    to_room: str = Field(..., description="Target room ID or 'corridor' / 'foyer'")
    x: float = Field(..., description="Door center X position")
    y: float = Field(..., description="Door center Y position")
    width: float = Field(default=3.0, description="Clear door width in feet/meters")
    wall: str = Field(..., description="Wall orientation where door sits (north, south, east, west)")
    is_exterior: bool = Field(default=False, description="Whether this is an exterior door")
    swing: str = Field(default="inward", description="Door swing direction")


class WindowOutput(BaseModel):
    id: str = Field(..., description="Unique window identifier")
    room_id: str = Field(..., description="Associated room ID")
    x: float = Field(..., description="Window center X position")
    y: float = Field(..., description="Window center Y position")
    width: float = Field(default=4.0, description="Window width in feet/meters")
    wall: str = Field(..., description="Wall orientation where window sits (north, south, east, west)")
    exterior_facing: str = Field(..., description="Exterior facing direction (front, rear, left, right)")


class CirculationPathOutput(BaseModel):
    id: str = Field(..., description="Unique circulation path ID")
    name: str = Field(..., description="Name of passage (e.g., Main Foyer, Central Corridor)")
    x: float = Field(..., description="X position of path origin")
    y: float = Field(..., description="Y position of path origin")
    width: float = Field(..., description="Corridor width")
    length: float = Field(..., description="Corridor length")
    area: float = Field(..., description="Circulation area")


class SpatialBreakdownOutput(BaseModel):
    total_plot_area: float = Field(..., description="Total gross plot area")
    net_room_area: float = Field(..., description="Sum of net usable interior room areas")
    circulation_area: float = Field(..., description="Sum of explicit corridors and foyers")
    wall_area: float = Field(..., description="Structural footprint area of exterior and interior walls")
    open_unallocated_area: float = Field(..., description="Open lawn, courtyard, OTS, or unbuilt area")
    setback_area: float = Field(default=0.0, description="Dedicated boundary setback area")
    total_covered_area: float = Field(..., description="Total covered footprint (rooms + circulation + walls)")
    utilization_percentage: float = Field(..., description="Percentage of plot covered by building footprint")


class PlotDimensionsOutput(BaseModel):
    length: float = Field(..., description="Plot total length")
    width: float = Field(..., description="Plot total width")
    front_width: float = Field(..., description="Plot front width")
    total_area: float = Field(..., description="Total plot area")
    buildable_area: float = Field(..., description="Buildable area after applying setbacks")
    unit: str = Field(..., description="Measurement unit (feet or meters)")
    entrance_orientation: str = Field(..., description="Entrance orientation")


class RecommendationOutput(BaseModel):
    category: str = Field(..., description="Category: orientation, ventilation, zoning, or spatial_utilization")
    title: str = Field(..., description="Short recommendation heading")
    description: str = Field(..., description="Detailed architectural and environmental insight")
    score: Optional[float] = Field(default=None, description="Score or index metric if applicable")


class PlanAlternative(BaseModel):
    """A distinct feasible layout alternative (e.g. Plan A: Open Living vs Plan B: Privacy Focused)."""
    layout_type: str = Field(..., description="e.g. 'open_living' or 'privacy_focused'")
    title: str = Field(..., description="Human readable title (e.g. 'Plan A: Open Living Concept')")
    description: str = Field(..., description="Summary of layout approach and advantages")
    rooms: List[RoomOutput] = Field(..., description="Allocated rooms")
    circulation_paths: List[CirculationPathOutput] = Field(default_factory=list, description="Explicit circulation paths")
    doors: List[DoorOutput] = Field(default_factory=list, description="Doors connecting rooms and corridors")
    windows: List[WindowOutput] = Field(default_factory=list, description="Exterior windows")
    spatial_breakdown: SpatialBreakdownOutput = Field(..., description="Granular area breakdown")
    svg_floor_plan: str = Field(..., description="2D architectural SVG rendering")
    recommendations: List[RecommendationOutput] = Field(default_factory=list, description="Specific recommendations")
    is_feasible: bool = Field(default=True, description="Whether design passed all feasibility checks")
    connectivity_verified: bool = Field(default=True, description="Whether all rooms are reachably connected")


class PlanGenerateResponse(BaseModel):
    """Primary successful response for layout generation."""
    status: str = Field(default="success", description="Response status")
    plan_id: str = Field(..., description="Unique generated plan identifier")
    plot: PlotDimensionsOutput
    rooms: List[RoomOutput]
    total_built_area: float = Field(..., description="Sum of all allocated room areas")
    circulation_area: float = Field(..., description="Explicit circulation area (foyers and corridors)")
    utilization_percentage: float = Field(..., description="Percentage of buildable plot area utilized")
    svg_floor_plan: str = Field(..., description="Proportionally scaled 2D SVG markup")
    recommendations: List[RecommendationOutput]
    disclaimer: str = Field(default=MANDATORY_DISCLAIMER, description="Mandatory SP-AI-10 disclaimer notice")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Execution and solver metadata")

    # Phase 2 Enhanced Fields
    spatial_breakdown: Optional[SpatialBreakdownOutput] = Field(
        default=None, description="Granular spatial calculations (rooms, circulation, walls, open space)"
    )
    doors: List[DoorOutput] = Field(default_factory=list, description="Doorway positions and connections")
    windows: List[WindowOutput] = Field(default_factory=list, description="Verified exterior window placements")
    circulation_paths: List[CirculationPathOutput] = Field(default_factory=list, description="Explicit corridor geometry")
    alternatives: List[PlanAlternative] = Field(
        default_factory=list, description="Distinct layout alternatives (e.g. Plan A Open Living vs Plan B Privacy Focused)"
    )


class ErrorResponse(BaseModel):
    """Standard error response payload."""
    status: str = "error"
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None
