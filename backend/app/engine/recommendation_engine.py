"""Location-specific architectural recommendation engine per SP-AI-08."""
from typing import List
from backend.app.schemas.plot import OrientationEnum, PlotInput
from backend.app.schemas.response import RecommendationOutput, RoomOutput


class RecommendationEngine:
    """Generates location-specific, orientation, ventilation, and spatial utilization insights."""

    @classmethod
    def generate_recommendations(
        cls,
        plot: PlotInput,
        rooms: List[RoomOutput],
        total_plot_area: float,
        total_built_area: float,
        utilization_percentage: float,
    ) -> List[RecommendationOutput]:
        recs: List[RecommendationOutput] = []

        # 1. Orientation & Sun Path Analysis
        orient = plot.entrance_orientation
        if orient in [OrientationEnum.SOUTH, OrientationEnum.SOUTH_EAST, OrientationEnum.SOUTH_WEST]:
            recs.append(
                RecommendationOutput(
                    category="orientation",
                    title="Optimal South-Facing Solar Gain",
                    description=(
                        f"Your plot faces {orient.value}. Front-facing living areas and verandas will receive "
                        "abundant natural winter sunlight, significantly reducing artificial heating needs. "
                        "Consider deep window overhangs (chhajjas) on the front facade to block harsh midday summer sun."
                    ),
                    score=0.92,
                )
            )
        elif orient in [OrientationEnum.NORTH, OrientationEnum.NORTH_EAST, OrientationEnum.NORTH_WEST]:
            recs.append(
                RecommendationOutput(
                    category="orientation",
                    title="Diffused Glare-Free North Light",
                    description=(
                        f"Plots facing {orient.value} enjoy steady, glare-free northern illumination throughout the day. "
                        "This orientation keeps front rooms cooler during hot summer months and provides ideal conditions "
                        "for study spaces, workspaces, or open dining lounges."
                    ),
                    score=0.88,
                )
            )
        elif orient == OrientationEnum.EAST:
            recs.append(
                RecommendationOutput(
                    category="orientation",
                    title="Morning Sun & Energizing Facade",
                    description=(
                        "An East-facing orientation provides gentle morning sunlight. Positioning the kitchen and "
                        "breakfast corner along the front-east boundary maximizes early daylight and natural morning warmth."
                    ),
                    score=0.90,
                )
            )
        elif orient == OrientationEnum.WEST:
            recs.append(
                RecommendationOutput(
                    category="orientation",
                    title="West-Facing Thermal Buffer Advisory",
                    description=(
                        "West-facing plots absorb high solar thermal radiation in the late afternoon. It is strongly "
                        "recommended to use the car porch, staircase tower, or landscaped buffer along the west facade "
                        "to insulate interior living spaces from heat buildup."
                    ),
                    score=0.75,
                )
            )

        # 2. Natural Cross-Ventilation & Airflow
        recs.append(
            RecommendationOutput(
                category="ventilation",
                title="Cross-Ventilation & Light Shaft Planning",
                description=(
                    "For continuous fresh airflow in attached bathrooms and rear bedrooms, incorporate a minimum "
                    "3x4 ft open-to-sky (OTS) ventilation duct or rear shaft. This prevents humidity accumulation and "
                    "ensures compliance with residential building bylaws."
                ),
                score=0.85,
            )
        )

        # 3. Privacy & Functional Zoning
        recs.append(
            RecommendationOutput(
                category="zoning",
                title="Acoustic & Visual Privacy Zoning",
                description=(
                    "The layout enforces clear functional stratification: high-traffic zones (porch and living room) "
                    "are clustered near the entrance, while sleeping quarters are secluded towards the rear for privacy "
                    "and reduced street noise."
                ),
                score=0.95,
            )
        )

        # 4. Spatial Utilization & Bylaw Conformance
        if utilization_percentage > 85.0:
            recs.append(
                RecommendationOutput(
                    category="spatial_utilization",
                    title="High Plot Coverage Advisory",
                    description=(
                        f"Current ground coverage is {utilization_percentage:.1f}%. Most municipal development authorities "
                        "(e.g., CDA, LDA, PDA) mandate maximum ground coverage between 65% and 75% for residential plots "
                        "to guarantee mandatory front/rear setbacks and green space."
                    ),
                    score=0.65,
                )
            )
        else:
            recs.append(
                RecommendationOutput(
                    category="spatial_utilization",
                    title="Balanced Footprint & Open Space",
                    description=(
                        f"Spatial utilization stands at {utilization_percentage:.1f}%, leaving healthy open margins for "
                        "setbacks, drainage, exterior maintenance, and natural daylight penetration."
                    ),
                    score=0.90,
                )
            )

        return recs
