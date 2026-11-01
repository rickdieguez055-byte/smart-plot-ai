"""Layout requirements and request models per SP-AI-01, SP-AI-02."""
from typing import Optional
from pydantic import BaseModel, Field
from backend.app.schemas.plot import PlotInput


class LayoutRequirements(BaseModel):
    """User-specified functional layout requirements per SP-AI-02."""
    bedrooms: int = Field(default=2, ge=1, le=8, description="Number of bedrooms (1-8)")
    bathrooms: int = Field(default=2, ge=1, le=8, description="Number of bathrooms (1-8)")
    floors: int = Field(default=1, ge=1, le=3, description="Number of floors (1-3, default 1)")
    kitchen: bool = Field(default=True, description="Include dedicated kitchen")
    living_room: bool = Field(default=True, description="Include living room / lounge")
    parking: bool = Field(default=True, description="Include car porch / parking")
    dining_room: bool = Field(default=False, description="Include dedicated dining area")
    lawn: bool = Field(default=False, description="Include front or rear lawn")
    store_room: bool = Field(default=False, description="Include store room")


class PlanGenerateRequest(BaseModel):
    """Full generation request payload."""
    plot: PlotInput
    requirements: Optional[LayoutRequirements] = Field(
        default_factory=LayoutRequirements,
        description="Layout preferences and room counts",
    )
