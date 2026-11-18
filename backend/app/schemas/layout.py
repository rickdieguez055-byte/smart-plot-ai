"""Layout requirements and request models per SP-AI-01, SP-AI-02."""
from typing import Optional
from pydantic import BaseModel, Field, field_validator
from backend.app.schemas.plot import PlotInput


class SingleFloorRequirement(BaseModel):
    """Floor-specific functional room allocation for independent per-floor customization."""
    bedrooms: int = Field(default=1, ge=0, le=5, description="Number of bedrooms on this floor (0-5)")
    bathrooms: int = Field(default=1, ge=0, le=5, description="Number of bathrooms on this floor (0-5)")
    kitchen: bool = Field(default=False, description="Dedicated kitchen on this floor")
    living_room: bool = Field(default=False, description="Living room / family lounge on this floor")
    drawing_room: bool = Field(default=False, description="Formal guest drawing room on this floor")
    terrace: bool = Field(default=False, description="Open terrace or balcony on this floor")
    store_room: bool = Field(default=False, description="Dedicated store room on this floor")


class LayoutRequirements(BaseModel):
    """User-specified functional layout requirements per SP-AI-02."""
    bedrooms: int = Field(default=2, ge=1, le=8, description="Number of bedrooms (1-8)")
    bathrooms: int = Field(default=2, ge=1, le=8, description="Number of bathrooms (1-8)")
    floors: int = Field(default=1, ge=1, le=2, description="Number of floors (1 for Ground Floor, 2 for Ground + First Floor)")
    kitchen: bool = Field(default=True, description="Include dedicated kitchen")
    living_room: bool = Field(default=True, description="Include living room / lounge")
    parking: bool = Field(default=True, description="Include car porch / parking")
    dining_room: bool = Field(default=False, description="Include dedicated dining area")
    lawn: bool = Field(default=False, description="Include front or rear lawn")
    store_room: bool = Field(default=False, description="Include store room")

    # Floor-specific independent room specifications
    ground_floor: Optional[SingleFloorRequirement] = Field(
        default=None, description="Independent Ground Floor room requirements"
    )
    first_floor: Optional[SingleFloorRequirement] = Field(
        default=None, description="Independent First Floor room requirements"
    )

    @field_validator("floors")
    @classmethod
    def validate_floors(cls, v: int) -> int:
        if v > 2:
            raise ValueError(
                "Multi-floor generation supports up to 2 floors (Ground Floor + First Floor) in Phase 6. "
                "High-rise / 3+ floor generation requires advanced structural elevator shafts scheduled for future phases."
            )
        if v < 1:
            raise ValueError("Number of floors must be at least 1.")
        return v

    def model_post_init(self, __context) -> None:
        """Validate cross-floor consistency when floor-specific requirements are provided."""
        if self.floors == 1 and self.first_floor is not None:
            raise ValueError("first_floor requirements cannot be specified for single-story layouts (floors=1).")

        if self.floors == 2 and self.ground_floor is not None and self.first_floor is not None:
            total_beds = self.ground_floor.bedrooms + self.first_floor.bedrooms
            total_baths = self.ground_floor.bathrooms + self.first_floor.bathrooms
            if total_beds < 1:
                raise ValueError("At least 1 bedroom must be specified across the residence.")
            if total_beds > 6:
                raise ValueError(f"Total bedrooms across floors ({total_beds}) exceeds maximum residential limit of 6.")
            if total_baths < 1:
                raise ValueError("At least 1 bathroom must be specified across the residence.")
            if total_baths > 5:
                raise ValueError(f"Total bathrooms across floors ({total_baths}) exceeds maximum residential limit of 5.")
            # Synchronize aggregate counters with floor-specific sums
            self.bedrooms = total_beds
            self.bathrooms = total_baths


class PlanGenerateRequest(BaseModel):
    """Full generation request payload."""
    plot: PlotInput
    requirements: Optional[LayoutRequirements] = Field(
        default_factory=LayoutRequirements,
        description="Layout preferences and room counts",
    )
