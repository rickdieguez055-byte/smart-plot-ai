"""Plot input schemas and validation."""
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, field_validator


class OrientationEnum(str, Enum):
    NORTH = "North"
    SOUTH = "South"
    EAST = "East"
    WEST = "West"
    NORTH_EAST = "North-East"
    NORTH_WEST = "North-West"
    SOUTH_EAST = "South-East"
    SOUTH_WEST = "South-West"


class PlotUnit(str, Enum):
    FEET = "feet"
    METERS = "meters"


class SetbackInput(BaseModel):
    front: float = Field(default=0.0, ge=0.0, description="Front setback from boundary")
    rear: float = Field(default=0.0, ge=0.0, description="Rear setback from boundary")
    left: float = Field(default=0.0, ge=0.0, description="Left setback from boundary")
    right: float = Field(default=0.0, ge=0.0, description="Right setback from boundary")


class PlotInput(BaseModel):
    """Plot physical and dimensional parameters per SP-AI-01 and SP-AI-03."""
    plot_length: float = Field(..., gt=0.0, description="Total length/depth of the plot (positive numeric)")
    plot_width: float = Field(..., gt=0.0, description="Total width of the plot (positive numeric)")
    front_width: float = Field(..., gt=0.0, description="Front width of the plot along road entrance")
    entrance_orientation: OrientationEnum = Field(..., description="Entrance facing orientation")
    unit: PlotUnit = Field(default=PlotUnit.FEET, description="Measurement unit (feet or meters)")
    setbacks: Optional[SetbackInput] = Field(default=None, description="Optional setback rules")

    @field_validator("entrance_orientation", mode="before")
    @classmethod
    def normalize_orientation(cls, v: str) -> str:
        if isinstance(v, str):
            clean = v.strip().lower().replace("_", "-")
            mapping = {
                "north": "North",
                "n": "North",
                "south": "South",
                "s": "South",
                "east": "East",
                "e": "East",
                "west": "West",
                "w": "West",
                "north-east": "North-East",
                "northeast": "North-East",
                "ne": "North-East",
                "north-west": "North-West",
                "northwest": "North-West",
                "nw": "North-West",
                "south-east": "South-East",
                "southeast": "South-East",
                "se": "South-East",
                "south-west": "South-West",
                "southwest": "South-West",
                "sw": "South-West",
            }
            if clean in mapping:
                return mapping[clean]
        return v

    @field_validator("front_width")
    @classmethod
    def validate_front_width(cls, v: float, info) -> float:
        # Check against plot dimensions if available in validation context
        data = info.data
        length = data.get("plot_length")
        width = data.get("plot_width")
        if length and width:
            max_dim = max(length, width)
            if v > max_dim * 1.05:  # small 5% margin for survey variations
                raise ValueError(
                    f"Front width ({v}) cannot be significantly larger than maximum plot dimension ({max_dim})."
                )
        return v
