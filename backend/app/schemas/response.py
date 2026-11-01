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
    category: str = Field(..., description="Room category (bedroom, bathroom, kitchen, living, parking, circulation)")
    x: float = Field(..., description="X-coordinate of bottom-left origin in plot coordinate system")
    y: float = Field(..., description="Y-coordinate of bottom-left origin in plot coordinate system")
    width: float = Field(..., description="Room width along X axis")
    length: float = Field(..., description="Room length/depth along Y axis")
    area: float = Field(..., description="Room area (width * length)")
    floor: int = Field(default=1, description="Floor level (1 for Ground Floor)")


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


class PlanGenerateResponse(BaseModel):
    """Primary successful response for layout generation."""
    status: str = Field(default="success", description="Response status")
    plan_id: str = Field(..., description="Unique generated plan identifier")
    plot: PlotDimensionsOutput
    rooms: List[RoomOutput]
    total_built_area: float = Field(..., description="Sum of all allocated room areas")
    circulation_area: float = Field(..., description="Circulation, hallway, and wall footprint area")
    utilization_percentage: float = Field(..., description="Percentage of buildable plot area utilized")
    svg_floor_plan: str = Field(..., description="Proportionally scaled 2D SVG markup")
    recommendations: List[RecommendationOutput]
    disclaimer: str = Field(default=MANDATORY_DISCLAIMER, description="Mandatory SP-AI-10 disclaimer notice")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Execution and solver metadata")


class ErrorResponse(BaseModel):
    """Standard error response payload."""
    status: str = "error"
    code: str
    message: str
    details: Optional[Dict[str, Any]] = None
