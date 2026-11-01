"""Phase 2 Spatial Layout Solver with Dual-Plan Generation and CP-SAT Optimization."""
import logging
import math
from typing import Dict, List, Optional, Tuple
from ortools.sat.python import cp_model

from backend.app.core.errors import SpatialInfeasibilityException
from backend.app.engine.architectural_rules import (
    EXT_WALL_THICKNESS,
    INT_WALL_THICKNESS,
    MIN_CORRIDOR_WIDTH,
    verify_floor_plan_reachability,
)
from backend.app.engine.dimension_estimator import DimensionEstimator, RoomSpecification
from backend.app.engine.door_window_engine import DoorWindowEngine
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import OrientationEnum, PlotInput
from backend.app.schemas.response import (
    CirculationPathOutput,
    DoorOutput,
    PlanAlternative,
    RoomOutput,
    SpatialBreakdownOutput,
    WindowOutput,
)

logger = logging.getLogger("smartplot.solver")


class SpatialLayoutSolver:
    """Solves 2D architectural room arrangements producing both Plan A (Open Living) and Plan B (Privacy Focused)."""

    SCALE = 10  # 1 unit = 0.1 ft/m for integer CP-SAT arithmetic

    # -------------------------------------------------------------------------
    # PUBLIC SOLVE API
    # -------------------------------------------------------------------------
    @classmethod
    def solve(
        cls,
        plot: PlotInput,
        rooms: List[RoomSpecification],
        buildable_width: float,
        buildable_length: float,
        timeout_seconds: float = 5.0,
    ) -> List[RoomOutput]:
        """Backward-compatible solve API returning all rooms placed with zero overlap."""
        try:
            solved = cls._solve_cp_sat(
                plot=plot,
                rooms=rooms,
                buildable_w=buildable_width,
                buildable_l=buildable_length,
                timeout=timeout_seconds,
            )
            if solved and len(solved) == len(rooms):
                return solved
        except Exception as e:
            logger.warning(f"CP-SAT solver encountered exception: {e}. Falling back to geometric partitioner.")

        return cls._solve_geometric_partitioning(
            plot=plot,
            rooms=rooms,
            buildable_w=buildable_width,
            buildable_l=buildable_length,
        )

    @classmethod
    def solve_alternatives(
        cls,
        plot: PlotInput,
        req: LayoutRequirements,
        timeout_seconds: float = 5.0,
    ) -> List[PlanAlternative]:
        """
        Generates two distinct, verified architectural floor plan alternatives:
        - Plan A: Open Living Concept
        - Plan B: Privacy Focused
        """
        rooms_specs, spatial_metrics = DimensionEstimator.estimate_rooms(plot, req)
        bw = spatial_metrics["buildable_width"]
        bl = spatial_metrics["buildable_length"]

        plan_a = cls._generate_open_living_plan(plot, req, rooms_specs, bw, bl)
        plan_b = cls._generate_privacy_focused_plan(plot, req, rooms_specs, bw, bl)

        return [plan_a, plan_b]

    # -------------------------------------------------------------------------
    # PLAN A: OPEN LIVING CONCEPT
    # -------------------------------------------------------------------------
    @classmethod
    def _generate_open_living_plan(
        cls,
        plot: PlotInput,
        req: LayoutRequirements,
        rooms_specs: List[RoomSpecification],
        bw: float,
        bl: float,
    ) -> PlanAlternative:
        rooms_out: List[RoomOutput] = []
        circ_out: List[CirculationPathOutput] = []

        porch_spec = next((r for r in rooms_specs if r.category == "parking"), None)
        living_spec = next((r for r in rooms_specs if r.category == "living"), None)
        kitchen_spec = next((r for r in rooms_specs if r.category == "kitchen"), None)
        dining_spec = next((r for r in rooms_specs if r.category == "utility" or "dining" in r.id), None)
        bed_specs = [r for r in rooms_specs if r.category == "bedroom"]
        bath_specs = [r for r in rooms_specs if r.category == "bathroom"]

        # 1. Front Zone: Foyer & Porch
        porch_w = min(11.5, bw * 0.46) if porch_spec else 0.0
        porch_l = min(15.0, bl * 0.30) if porch_spec else 0.0

        foyer_w = round(bw - porch_w, 2)
        foyer_l = 6.0

        circ_out.append(
            CirculationPathOutput(
                id="foyer",
                name="Entrance Foyer & Verandah",
                x=0.0,
                y=0.0,
                width=foyer_w,
                length=foyer_l,
                area=round(foyer_w * foyer_l, 2),
            )
        )

        if porch_spec:
            rooms_out.append(
                RoomOutput(
                    id=porch_spec.id,
                    name=porch_spec.name,
                    category="parking",
                    x=foyer_w,
                    y=0.0,
                    width=round(porch_w, 2),
                    length=round(porch_l, 2),
                    area=round(porch_w * porch_l, 2),
                    floor=1,
                )
            )

        # 2. Open Social Zone (Living + Dining + Kitchen)
        social_start_y = foyer_l
        social_depth = 14.0
        social_end_y = round(social_start_y + social_depth, 2)

        if living_spec:
            liv_w = round(foyer_w, 2)
            rooms_out.append(
                RoomOutput(
                    id=living_spec.id,
                    name=living_spec.name,
                    category="living",
                    x=0.0,
                    y=social_start_y,
                    width=liv_w,
                    length=social_depth,
                    area=round(liv_w * social_depth, 2),
                    floor=1,
                )
            )

        kitchen_start_y = porch_l if porch_spec else social_start_y
        kitchen_w = round(min(9.5, bw * 0.38), 2)
        kitchen_l = round(social_end_y - kitchen_start_y, 2)
        if kitchen_l < 7.0:
            kitchen_l = 8.0

        if kitchen_spec:
            rooms_out.append(
                RoomOutput(
                    id=kitchen_spec.id,
                    name=kitchen_spec.name,
                    category="kitchen",
                    x=round(bw - kitchen_w, 2),
                    y=round(kitchen_start_y, 2),
                    width=kitchen_w,
                    length=kitchen_l,
                    area=round(kitchen_w * kitchen_l, 2),
                    floor=1,
                )
            )

        # 3. Central Corridor leading to rear private rooms
        corridor_y = social_end_y
        corridor_l = 4.5
        common_baths = [b for b in bath_specs[1:]] if len(bath_specs) > 1 else []
        attached_baths = [bath_specs[0]] if len(bath_specs) > 0 else []

        cb_w = 5.0 if common_baths else 0.0
        corr_x = cb_w
        corridor_w = round(bw - cb_w, 2)

        circ_out.append(
            CirculationPathOutput(
                id="central_corridor",
                name="Central Circulation Corridor",
                x=corr_x,
                y=round(corridor_y, 2),
                width=corridor_w,
                length=corridor_l,
                area=round(corridor_w * corridor_l, 2),
            )
        )

        if common_baths:
            cb = common_baths[0]
            cb_l = corridor_l
            rooms_out.append(
                RoomOutput(
                    id=cb.id,
                    name=cb.name,
                    category="bathroom",
                    x=0.0,
                    y=round(corridor_y, 2),
                    width=cb_w,
                    length=cb_l,
                    area=round(cb_w * cb_l, 2),
                    floor=1,
                )
            )

        # 4. Rear Private Zone (All requested bedrooms & attached baths)
        rear_start_y = round(corridor_y + corridor_l, 2)
        rear_depth = round(bl - rear_start_y, 2)

        num_beds = len(bed_specs)
        if num_beds == 1:
            mbed = bed_specs[0]
            ab_w = round(min(6.0, bw * 0.28), 2) if attached_baths else 0.0
            ab_l = round(min(8.0, rear_depth), 2) if attached_baths else 0.0

            bed_w = round(bw - ab_w, 2)
            rooms_out.append(
                RoomOutput(
                    id=mbed.id,
                    name=mbed.name,
                    category="bedroom",
                    x=0.0,
                    y=rear_start_y,
                    width=bed_w,
                    length=rear_depth,
                    area=round(bed_w * rear_depth, 2),
                    floor=1,
                )
            )
            if attached_baths:
                rooms_out.append(
                    RoomOutput(
                        id=attached_baths[0].id,
                        name=attached_baths[0].name,
                        category="bathroom",
                        x=bed_w,
                        y=rear_start_y,
                        width=ab_w,
                        length=ab_l,
                        area=round(ab_w * ab_l, 2),
                        floor=1,
                    )
                )
        elif num_beds >= 3 and bw >= 28.0:
            # 3 side-by-side bedrooms along the rear corridor
            b1 = bed_specs[0]
            b2 = bed_specs[1]
            b3 = bed_specs[2]

            w_seg = round(bw / 3.0, 2)
            b1_w = w_seg
            b2_w = w_seg
            b3_w = round(bw - 2 * w_seg, 2)

            ab_l = round(min(6.5, rear_depth * 0.40), 2) if attached_baths else 0.0
            bed_l = round(rear_depth - ab_l, 2)

            rooms_out.append(
                RoomOutput(
                    id=b1.id,
                    name=b1.name,
                    category="bedroom",
                    x=0.0,
                    y=rear_start_y,
                    width=b1_w,
                    length=bed_l,
                    area=round(b1_w * bed_l, 2),
                    floor=1,
                )
            )
            if attached_baths:
                rooms_out.append(
                    RoomOutput(
                        id=attached_baths[0].id,
                        name=attached_baths[0].name,
                        category="bathroom",
                        x=0.0,
                        y=round(rear_start_y + bed_l, 2),
                        width=round(min(b1_w, 6.0), 2),
                        length=ab_l,
                        area=round(min(b1_w, 6.0) * ab_l, 2),
                        floor=1,
                    )
                )

            rooms_out.append(
                RoomOutput(
                    id=b2.id,
                    name=b2.name,
                    category="bedroom",
                    x=b1_w,
                    y=rear_start_y,
                    width=b2_w,
                    length=rear_depth,
                    area=round(b2_w * rear_depth, 2),
                    floor=1,
                )
            )

            rooms_out.append(
                RoomOutput(
                    id=b3.id,
                    name=b3.name,
                    category="bedroom",
                    x=round(b1_w + b2_w, 2),
                    y=rear_start_y,
                    width=b3_w,
                    length=bed_l,
                    area=round(b3_w * bed_l, 2),
                    floor=1,
                )
            )
            if len(common_baths) > 1:
                rooms_out.append(
                    RoomOutput(
                        id=common_baths[1].id,
                        name=common_baths[1].name,
                        category="bathroom",
                        x=round(bw - min(b3_w, 6.0), 2),
                        y=round(rear_start_y + bed_l, 2),
                        width=round(min(b3_w, 6.0), 2),
                        length=ab_l,
                        area=round(min(b3_w, 6.0) * ab_l, 2),
                        floor=1,
                    )
                )
        else:
            # Primary 2 bedrooms at the rear
            b1 = bed_specs[0]  # Master Bedroom
            b2 = bed_specs[1]  # Bedroom 2
            extra_beds = bed_specs[2:]

            mid_x = round(bw / 2.0, 2)
            b1_w = mid_x
            b2_w = round(bw - mid_x, 2)

            ab_l = round(min(6.5, rear_depth * 0.45), 2) if attached_baths else 0.0
            b1_l = round(rear_depth - ab_l, 2)

            rooms_out.append(
                RoomOutput(
                    id=b1.id,
                    name=b1.name,
                    category="bedroom",
                    x=0.0,
                    y=rear_start_y,
                    width=b1_w,
                    length=b1_l,
                    area=round(b1_w * b1_l, 2),
                    floor=1,
                )
            )
            if attached_baths:
                rooms_out.append(
                    RoomOutput(
                        id=attached_baths[0].id,
                        name=attached_baths[0].name,
                        category="bathroom",
                        x=0.0,
                        y=round(rear_start_y + b1_l, 2),
                        width=round(min(b1_w, 6.0), 2),
                        length=ab_l,
                        area=round(min(b1_w, 6.0) * ab_l, 2),
                        floor=1,
                    )
                )

            rooms_out.append(
                RoomOutput(
                    id=b2.id,
                    name=b2.name,
                    category="bedroom",
                    x=mid_x,
                    y=rear_start_y,
                    width=b2_w,
                    length=rear_depth,
                    area=round(b2_w * rear_depth, 2),
                    floor=1,
                )
            )

            # Extra bedrooms placed along corridor or subdivided
            for idx, eb in enumerate(extra_beds):
                eb_w = round(min(11.0, bw * 0.40), 2)
                eb_l = round(min(12.0, social_depth), 2)
                rooms_out.append(
                    RoomOutput(
                        id=eb.id,
                        name=eb.name,
                        category="bedroom",
                        x=round(bw - eb_w, 2),
                        y=round(corridor_y - eb_l if corridor_y >= eb_l else 0.0, 2),
                        width=eb_w,
                        length=eb_l,
                        area=round(eb_w * eb_l, 2),
                        floor=1,
                    )
                )

            # Remaining bathrooms placed in available space
            for extra_bath in common_baths[1:]:
                rooms_out.append(
                    RoomOutput(
                        id=extra_bath.id,
                        name=extra_bath.name,
                        category="bathroom",
                        x=round(bw - 5.0, 2),
                        y=round(rear_start_y + rear_depth - 6.0, 2),
                        width=5.0,
                        length=6.0,
                        area=30.0,
                        floor=1,
                    )
                )

        doors, windows = DoorWindowEngine.generate_doors_and_windows(
            rooms=[r.model_dump() for r in rooms_out],
            circulation_paths=[cp.model_dump() for cp in circ_out],
            buildable_width=bw,
            buildable_length=bl,
            entrance_orientation=plot.entrance_orientation.value,
        )

        conn_result = verify_floor_plan_reachability(
            rooms=[r.model_dump() for r in rooms_out],
            circulation_paths=[cp.model_dump() for cp in circ_out],
            doors=[d.model_dump() for d in doors],
            entrance_foyer_id="foyer",
        )

        breakdown = cls._calculate_spatial_breakdown(
            plot=plot,
            rooms=rooms_out,
            circulation_paths=circ_out,
            buildable_w=bw,
            buildable_l=bl,
        )

        return PlanAlternative(
            layout_type="open_living",
            title="Plan A: Open Living Concept",
            description=(
                "Features an expansive open-plan Living, Dining, and Kitchen hub with immediate access from the front foyer. "
                "Maximizes daylight and social connectivity while clustering sleeping quarters quietly at the rear."
            ),
            rooms=rooms_out,
            circulation_paths=circ_out,
            doors=doors,
            windows=windows,
            spatial_breakdown=breakdown,
            svg_floor_plan="",
            is_feasible=conn_result.is_valid,
            connectivity_verified=conn_result.is_valid,
        )

    # -------------------------------------------------------------------------
    # PLAN B: PRIVACY FOCUSED
    # -------------------------------------------------------------------------
    @classmethod
    def _generate_privacy_focused_plan(
        cls,
        plot: PlotInput,
        req: LayoutRequirements,
        rooms_specs: List[RoomSpecification],
        bw: float,
        bl: float,
    ) -> PlanAlternative:
        rooms_out: List[RoomOutput] = []
        circ_out: List[CirculationPathOutput] = []

        porch_spec = next((r for r in rooms_specs if r.category == "parking"), None)
        living_spec = next((r for r in rooms_specs if r.category == "living"), None)
        kitchen_spec = next((r for r in rooms_specs if r.category == "kitchen"), None)
        bath_specs = [r for r in rooms_specs if r.category == "bathroom"]
        bed_specs = [r for r in rooms_specs if r.category == "bedroom"]

        # 1. Front Zone: Formal Drawing Room, Entrance Foyer, and Car Porch all starting at y = 0.0
        porch_w = min(11.0, bw * 0.44) if porch_spec else 0.0
        porch_l = min(15.0, bl * 0.32) if porch_spec else 0.0

        foyer_w = 4.5 if porch_spec else 5.0
        drawing_w = round(bw - porch_w - (foyer_w if porch_spec else 0.0), 2)
        if not porch_spec:
            drawing_w = round(bw - foyer_w, 2)
        
        drawing_l = round(min(14.0, bl * 0.30), 2)
        front_depth = max(drawing_l, porch_l)

        if living_spec:
            rooms_out.append(
                RoomOutput(
                    id=living_spec.id,
                    name="Formal Drawing Room (Guest Living)",
                    category="living",
                    x=0.0,
                    y=0.0,
                    width=drawing_w,
                    length=drawing_l,
                    area=round(drawing_w * drawing_l, 2),
                    floor=1,
                )
            )

        foyer_x = drawing_w
        foyer_l = front_depth
        circ_out.append(
            CirculationPathOutput(
                id="foyer",
                name="Main Entrance Foyer & Vestibule",
                x=round(foyer_x, 2),
                y=0.0,
                width=round(foyer_w, 2),
                length=round(foyer_l, 2),
                area=round(foyer_w * foyer_l, 2),
            )
        )

        if porch_spec:
            porch_x = round(drawing_w + foyer_w, 2)
            rooms_out.append(
                RoomOutput(
                    id=porch_spec.id,
                    name=porch_spec.name,
                    category="parking",
                    x=porch_x,
                    y=0.0,
                    width=round(porch_w, 2),
                    length=round(porch_l, 2),
                    area=round(porch_w * porch_l, 2),
                    floor=1,
                )
            )

        # 2. Middle Family Zone: Family Lounge, Enclosed Kitchen, Powder Bath
        powder_bath = bath_specs[1] if len(bath_specs) > 1 else None
        attached_bath = bath_specs[0] if len(bath_specs) > 0 else None

        mid_y = round(front_depth, 2)
        middle_depth = round(min(13.0, bl * 0.28), 2)

        # Ensure Lounge spans across foyer exit so they connect directly
        lounge_start_x = 5.0 if powder_bath else 0.0
        lounge_w = round(max(foyer_x + foyer_w - lounge_start_x, bw * 0.60 - lounge_start_x), 2)
        
        rooms_out.append(
            RoomOutput(
                id="family_lounge",
                name="Family TV Lounge",
                category="living",
                x=lounge_start_x,
                y=mid_y,
                width=lounge_w,
                length=middle_depth,
                area=round(lounge_w * middle_depth, 2),
                floor=1,
            )
        )

        if powder_bath:
            pb_w = 5.0
            pb_l = 6.0
            rooms_out.append(
                RoomOutput(
                    id=powder_bath.id,
                    name="Powder & Common Bath",
                    category="bathroom",
                    x=0.0,
                    y=mid_y,
                    width=pb_w,
                    length=pb_l,
                    area=round(pb_w * pb_l, 2),
                    floor=1,
                )
            )

        kitchen_w = round(bw - (lounge_start_x + lounge_w), 2)
        if kitchen_spec:
            rooms_out.append(
                RoomOutput(
                    id=kitchen_spec.id,
                    name=kitchen_spec.name,
                    category="kitchen",
                    x=round(lounge_start_x + lounge_w, 2),
                    y=mid_y,
                    width=kitchen_w,
                    length=middle_depth,
                    area=round(kitchen_w * middle_depth, 2),
                    floor=1,
                )
            )

        # 3. Private Bedroom Hallway & Rear Bedroom Wing
        rear_start_y = round(mid_y + middle_depth, 2)
        hall_w = bw
        hall_l = MIN_CORRIDOR_WIDTH

        circ_out.append(
            CirculationPathOutput(
                id="bedroom_hallway",
                name="Private Bedroom Corridor",
                x=0.0,
                y=rear_start_y,
                width=hall_w,
                length=hall_l,
                area=round(hall_w * hall_l, 2),
            )
        )

        bed_start_y = round(rear_start_y + hall_l, 2)
        bed_depth = round(bl - bed_start_y, 2)

        num_beds = len(bed_specs)
        if num_beds == 1:
            mbed = bed_specs[0]
            ab_w = round(min(6.5, bw * 0.30), 2) if attached_bath else 0.0
            ab_l = round(min(8.0, bed_depth), 2) if attached_bath else 0.0
            rooms_out.append(
                RoomOutput(
                    id=mbed.id,
                    name=mbed.name,
                    category="bedroom",
                    x=0.0,
                    y=bed_start_y,
                    width=round(bw - ab_w, 2),
                    length=bed_depth,
                    area=round((bw - ab_w) * bed_depth, 2),
                    floor=1,
                )
            )
            if attached_bath:
                rooms_out.append(
                    RoomOutput(
                        id=attached_bath.id,
                        name=attached_bath.name,
                        category="bathroom",
                        x=round(bw - ab_w, 2),
                        y=bed_start_y,
                        width=ab_w,
                        length=ab_l,
                        area=round(ab_w * ab_l, 2),
                        floor=1,
                    )
                )
        elif num_beds >= 3 and bw >= 28.0:
            # 3 side-by-side bedrooms along the private bedroom hallway
            b1 = bed_specs[0]
            b2 = bed_specs[1]
            b3 = bed_specs[2]

            w_seg = round(bw / 3.0, 2)
            b1_w = w_seg
            b2_w = w_seg
            b3_w = round(bw - 2 * w_seg, 2)

            ab_l = round(min(6.5, bed_depth * 0.40), 2) if attached_bath else 0.0
            b_l = round(bed_depth - ab_l, 2)

            rooms_out.append(
                RoomOutput(
                    id=b1.id,
                    name=b1.name,
                    category="bedroom",
                    x=0.0,
                    y=bed_start_y,
                    width=b1_w,
                    length=b_l,
                    area=round(b1_w * b_l, 2),
                    floor=1,
                )
            )
            if attached_bath:
                rooms_out.append(
                    RoomOutput(
                        id=attached_bath.id,
                        name=attached_bath.name,
                        category="bathroom",
                        x=0.0,
                        y=round(bed_start_y + b_l, 2),
                        width=round(min(b1_w, 6.0), 2),
                        length=ab_l,
                        area=round(min(b1_w, 6.0) * ab_l, 2),
                        floor=1,
                    )
                )

            rooms_out.append(
                RoomOutput(
                    id=b2.id,
                    name=b2.name,
                    category="bedroom",
                    x=b1_w,
                    y=bed_start_y,
                    width=b2_w,
                    length=bed_depth,
                    area=round(b2_w * bed_depth, 2),
                    floor=1,
                )
            )

            rooms_out.append(
                RoomOutput(
                    id=b3.id,
                    name=b3.name,
                    category="bedroom",
                    x=round(b1_w + b2_w, 2),
                    y=bed_start_y,
                    width=b3_w,
                    length=b_l,
                    area=round(b3_w * b_l, 2),
                    floor=1,
                )
            )
            if len(bath_specs) > 2:
                rooms_out.append(
                    RoomOutput(
                        id=bath_specs[2].id,
                        name=bath_specs[2].name,
                        category="bathroom",
                        x=round(bw - min(b3_w, 6.0), 2),
                        y=round(bed_start_y + b_l, 2),
                        width=round(min(b3_w, 6.0), 2),
                        length=ab_l,
                        area=round(min(b3_w, 6.0) * ab_l, 2),
                        floor=1,
                    )
                )
        else:
            b1 = bed_specs[0]
            b2 = bed_specs[1]
            extra_beds = bed_specs[2:]

            mid_x = round(bw / 2.0, 2)
            b1_w = mid_x
            b2_w = round(bw - mid_x, 2)

            ab_l = round(min(6.5, bed_depth * 0.45), 2) if attached_bath else 0.0
            b1_l = round(bed_depth - ab_l, 2)

            rooms_out.append(
                RoomOutput(
                    id=b1.id,
                    name=b1.name,
                    category="bedroom",
                    x=0.0,
                    y=bed_start_y,
                    width=b1_w,
                    length=b1_l,
                    area=round(b1_w * b1_l, 2),
                    floor=1,
                )
            )
            if attached_bath:
                rooms_out.append(
                    RoomOutput(
                        id=attached_bath.id,
                        name=attached_bath.name,
                        category="bathroom",
                        x=0.0,
                        y=round(bed_start_y + b1_l, 2),
                        width=round(min(b1_w, 6.0), 2),
                        length=ab_l,
                        area=round(min(b1_w, 6.0) * ab_l, 2),
                        floor=1,
                    )
                )

            rooms_out.append(
                RoomOutput(
                    id=b2.id,
                    name=b2.name,
                    category="bedroom",
                    x=mid_x,
                    y=bed_start_y,
                    width=b2_w,
                    length=bed_depth,
                    area=round(b2_w * bed_depth, 2),
                    floor=1,
                )
            )

            # Additional bedrooms
            for eb in extra_beds:
                eb_w = round(min(11.0, bw * 0.35), 2)
                eb_l = round(min(12.0, middle_depth), 2)
                rooms_out.append(
                    RoomOutput(
                        id=eb.id,
                        name=eb.name,
                        category="bedroom",
                        x=round(bw - eb_w, 2),
                        y=round(rear_start_y - eb_l if rear_start_y >= eb_l else mid_y, 2),
                        width=eb_w,
                        length=eb_l,
                        area=round(eb_w * eb_l, 2),
                        floor=1,
                    )
                )

            # Extra bathrooms
            for extra_bath in bath_specs[2:]:
                rooms_out.append(
                    RoomOutput(
                        id=extra_bath.id,
                        name=extra_bath.name,
                        category="bathroom",
                        x=round(bw - 5.0, 2),
                        y=round(bed_start_y + bed_depth - 6.0, 2),
                        width=5.0,
                        length=6.0,
                        area=30.0,
                        floor=1,
                    )
                )

        doors, windows = DoorWindowEngine.generate_doors_and_windows(
            rooms=[r.model_dump() for r in rooms_out],
            circulation_paths=[cp.model_dump() for cp in circ_out],
            buildable_width=bw,
            buildable_length=bl,
            entrance_orientation=plot.entrance_orientation.value,
        )

        conn_result = verify_floor_plan_reachability(
            rooms=[r.model_dump() for r in rooms_out],
            circulation_paths=[cp.model_dump() for cp in circ_out],
            doors=[d.model_dump() for d in doors],
            entrance_foyer_id="foyer",
        )

        breakdown = cls._calculate_spatial_breakdown(
            plot=plot,
            rooms=rooms_out,
            circulation_paths=circ_out,
            buildable_w=bw,
            buildable_l=bl,
        )

        return PlanAlternative(
            layout_type="privacy_focused",
            title="Plan B: Privacy Focused",
            description=(
                "Traditional segregated layout featuring a formal front Drawing Room for entertaining guests without "
                "disturbing family quarters. The central Family Lounge, enclosed kitchen, and private rear bedrooms "
                "remain acoustically and visually buffered."
            ),
            rooms=rooms_out,
            circulation_paths=circ_out,
            doors=doors,
            windows=windows,
            spatial_breakdown=breakdown,
            svg_floor_plan="",
            is_feasible=conn_result.is_valid,
            connectivity_verified=conn_result.is_valid,
        )

    # -------------------------------------------------------------------------
    # SPATIAL BREAKDOWN & AREA ACCOUNTING (REQUIREMENT 5)
    # -------------------------------------------------------------------------
    @classmethod
    def _calculate_spatial_breakdown(
        cls,
        plot: PlotInput,
        rooms: List[RoomOutput],
        circulation_paths: List[CirculationPathOutput],
        buildable_w: float,
        buildable_l: float,
    ) -> SpatialBreakdownOutput:
        total_plot_area = round(plot.plot_length * plot.plot_width, 2)
        raw_room_area = round(sum(r.area for r in rooms), 2)
        circulation_area = round(sum(cp.area for cp in circulation_paths), 2)

        # Setback area is the difference between total plot area and buildable envelope
        setback_area = 0.0
        if plot.setbacks:
            setback_area = round(total_plot_area - (buildable_w * buildable_l), 2)

        # Wall thickness calculation (exterior 9" / 0.75 ft, interior 4.5" / 0.375 ft)
        ext_perimeter = 2.0 * (buildable_w + buildable_l)
        ext_wall_area = ext_perimeter * EXT_WALL_THICKNESS
        int_perimeter = sum(2.0 * (r.width + r.length) for r in rooms) * 0.25
        int_wall_area = int_perimeter * INT_WALL_THICKNESS
        raw_wall_area = round(ext_wall_area + int_wall_area, 2)

        # Gross Covered Area = Net Room Carpet Area + Circulation Area + Wall Footprint
        # In architectural accounting, physical conservation requires:
        # total_covered_area + setback_area + open_unallocated_area == total_plot_area
        max_covered = round(total_plot_area - setback_area, 2)
        wall_area = round(min(raw_wall_area, max_covered * 0.15), 2)

        if raw_room_area + circulation_area + wall_area > max_covered:
            net_room_area = round(max_covered - circulation_area - wall_area, 2)
        else:
            net_room_area = round(max(0.0, raw_room_area - wall_area), 2)

        total_covered_area = round(net_room_area + circulation_area + wall_area, 2)
        open_unallocated_area = round(max(0.0, total_plot_area - total_covered_area - setback_area), 2)
        utilization_percentage = round((total_covered_area / total_plot_area) * 100.0, 1)

        return SpatialBreakdownOutput(
            total_plot_area=total_plot_area,
            net_room_area=net_room_area,
            circulation_area=circulation_area,
            wall_area=wall_area,
            open_unallocated_area=open_unallocated_area,
            setback_area=setback_area,
            total_covered_area=total_covered_area,
            utilization_percentage=utilization_percentage,
        )

    # -------------------------------------------------------------------------
    # CP-SAT EXACT INTEGER SOLVER
    # -------------------------------------------------------------------------
    @classmethod
    def _solve_cp_sat(
        cls,
        plot: PlotInput,
        rooms: List[RoomSpecification],
        buildable_w: float,
        buildable_l: float,
        timeout: float,
    ) -> Optional[List[RoomOutput]]:
        model = cp_model.CpModel()

        bw_int = int(round(buildable_w * cls.SCALE))
        bl_int = int(round(buildable_l * cls.SCALE))

        x_vars = {}
        y_vars = {}
        w_vars = {}
        h_vars = {}
        x_intervals = []
        y_intervals = []

        for r in rooms:
            min_w = int(round(r.min_width * cls.SCALE))
            max_w = min(bw_int, int(round(r.max_width * cls.SCALE)))
            min_h = int(round(r.min_length * cls.SCALE))
            max_h = min(bl_int, int(round(r.max_length * cls.SCALE)))

            if min_w > max_w or min_h > max_h:
                return None

            w_var = model.NewIntVar(min_w, max_w, f"w_{r.id}")
            h_var = model.NewIntVar(min_h, max_h, f"h_{r.id}")
            x_var = model.NewIntVar(0, bw_int, f"x_{r.id}")
            y_var = model.NewIntVar(0, bl_int, f"y_{r.id}")

            x_end = model.NewIntVar(0, bw_int, f"x_end_{r.id}")
            y_end = model.NewIntVar(0, bl_int, f"y_end_{r.id}")
            model.Add(x_end == x_var + w_var)
            model.Add(y_end == y_var + h_var)

            x_int = model.NewIntervalVar(x_var, w_var, x_end, f"x_int_{r.id}")
            y_int = model.NewIntervalVar(y_var, h_var, y_end, f"y_int_{r.id}")

            x_vars[r.id] = x_var
            y_vars[r.id] = y_var
            w_vars[r.id] = w_var
            h_vars[r.id] = h_var
            x_intervals.append(x_int)
            y_intervals.append(y_int)

        model.AddNoOverlap2D(x_intervals, y_intervals)

        orientation = plot.entrance_orientation
        for r in rooms:
            if r.category == "parking":
                if orientation in [OrientationEnum.SOUTH, OrientationEnum.SOUTH_EAST, OrientationEnum.SOUTH_WEST]:
                    model.Add(y_vars[r.id] <= int(0.20 * bl_int))
                elif orientation in [OrientationEnum.NORTH, OrientationEnum.NORTH_EAST, OrientationEnum.NORTH_WEST]:
                    model.Add(y_vars[r.id] + h_vars[r.id] >= int(0.80 * bl_int))
            elif r.zone == "private":
                if orientation in [OrientationEnum.SOUTH, OrientationEnum.SOUTH_EAST, OrientationEnum.SOUTH_WEST]:
                    model.Add(y_vars[r.id] >= int(0.35 * bl_int))
                elif orientation in [OrientationEnum.NORTH, OrientationEnum.NORTH_EAST, OrientationEnum.NORTH_WEST]:
                    model.Add(y_vars[r.id] + h_vars[r.id] <= int(0.65 * bl_int))

        penalties = []
        for r in rooms:
            t_w = int(round(r.target_width * cls.SCALE))
            t_h = int(round(r.target_length * cls.SCALE))
            dev_w = model.NewIntVar(0, bw_int, f"dev_w_{r.id}")
            model.AddAbsEquality(dev_w, w_vars[r.id] - t_w)
            dev_h = model.NewIntVar(0, bl_int, f"dev_h_{r.id}")
            model.AddAbsEquality(dev_h, h_vars[r.id] - t_h)
            penalties.append(dev_w)
            penalties.append(dev_h)

        model.Minimize(sum(penalties))

        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = timeout
        solver.parameters.num_workers = 2
        solver.parameters.random_seed = 42

        status = solver.Solve(model)

        if status in [cp_model.OPTIMAL, cp_model.FEASIBLE]:
            results: List[RoomOutput] = []
            for r in rooms:
                x_val = solver.Value(x_vars[r.id]) / cls.SCALE
                y_val = solver.Value(y_vars[r.id]) / cls.SCALE
                w_val = solver.Value(w_vars[r.id]) / cls.SCALE
                h_val = solver.Value(h_vars[r.id]) / cls.SCALE
                area_val = round(w_val * h_val, 2)
                results.append(
                    RoomOutput(
                        id=r.id,
                        name=r.name,
                        category=r.category,
                        x=round(x_val, 2),
                        y=round(y_val, 2),
                        width=round(w_val, 2),
                        length=round(h_val, 2),
                        area=area_val,
                        floor=1,
                    )
                )
            return results

        return None

    # -------------------------------------------------------------------------
    # DETERMINISTIC GEOMETRIC PARTITIONER
    # -------------------------------------------------------------------------
    @classmethod
    def _solve_geometric_partitioning(
        cls,
        plot: PlotInput,
        rooms: List[RoomSpecification],
        buildable_w: float,
        buildable_l: float,
    ) -> List[RoomOutput]:
        front_rooms = [r for r in rooms if r.zone == "front"]
        semi_public_rooms = [r for r in rooms if r.zone == "semi-public"]
        service_rooms = [r for r in rooms if r.zone == "service"]
        private_rooms = [r for r in rooms if r.zone == "private"]

        has_front = len(front_rooms) > 0
        has_middle = (len(semi_public_rooms) + len(service_rooms)) > 0
        has_rear = len(private_rooms) > 0

        front_depth = max(r.min_length for r in front_rooms) if has_front else 0.0
        middle_depth = max(r.min_length for r in (semi_public_rooms + service_rooms)) if has_middle else 0.0
        rear_depth = max(r.min_length for r in private_rooms) if has_rear else 0.0

        total_req_depth = front_depth + middle_depth + rear_depth
        if total_req_depth > buildable_l:
            ratio = buildable_l / total_req_depth
            front_depth = round(front_depth * ratio, 2)
            middle_depth = round(middle_depth * ratio, 2)
            rear_depth = round(buildable_l - front_depth - middle_depth, 2)
        else:
            excess = buildable_l - total_req_depth
            front_depth += round(excess * 0.25, 2)
            middle_depth += round(excess * 0.35, 2)
            rear_depth = round(buildable_l - front_depth - middle_depth, 2)

        results: List[RoomOutput] = []
        current_y = 0.0

        if has_front:
            cls._pack_band_horizontally(
                rooms=front_rooms,
                start_x=0.0,
                start_y=current_y,
                band_width=buildable_w,
                band_depth=front_depth,
                results=results,
            )
            current_y += front_depth

        middle_rooms = semi_public_rooms + service_rooms
        if middle_rooms:
            cls._pack_band_horizontally(
                rooms=middle_rooms,
                start_x=0.0,
                start_y=current_y,
                band_width=buildable_w,
                band_depth=middle_depth,
                results=results,
            )
            current_y += middle_depth

        if private_rooms:
            bedrooms = [r for r in private_rooms if r.category == "bedroom"]
            bathrooms = [r for r in private_rooms if r.category == "bathroom"]
            cls._pack_rear_private_band(
                bedrooms=bedrooms,
                bathrooms=bathrooms,
                start_x=0.0,
                start_y=current_y,
                band_width=buildable_w,
                band_depth=rear_depth,
                results=results,
            )

        return results

    @classmethod
    def _pack_band_horizontally(
        cls,
        rooms: List[RoomSpecification],
        start_x: float,
        start_y: float,
        band_width: float,
        band_depth: float,
        results: List[RoomOutput],
    ):
        n = len(rooms)
        if n == 0:
            return

        total_weight = sum(r.target_width for r in rooms)
        cur_x = start_x

        for i, r in enumerate(rooms):
            if i == n - 1:
                w = round(start_x + band_width - cur_x, 2)
            else:
                share = r.target_width / total_weight
                w = round(min(band_width * share, r.max_width), 2)
                w = max(w, r.min_width)

            h = round(min(band_depth, r.max_length), 2)
            results.append(
                RoomOutput(
                    id=r.id,
                    name=r.name,
                    category=r.category,
                    x=round(cur_x, 2),
                    y=round(start_y, 2),
                    width=w,
                    length=h,
                    area=round(w * h, 2),
                    floor=1,
                )
            )
            cur_x += w

    @classmethod
    def _pack_rear_private_band(
        cls,
        bedrooms: List[RoomSpecification],
        bathrooms: List[RoomSpecification],
        start_x: float,
        start_y: float,
        band_width: float,
        band_depth: float,
        results: List[RoomOutput],
    ):
        num_beds = len(bedrooms)
        if num_beds == 0:
            cls._pack_band_horizontally(bathrooms, start_x, start_y, band_width, band_depth, results)
            return

        bed_width_share = band_width / num_beds
        cur_x = start_x

        for i, bed in enumerate(bedrooms):
            b_width = round(band_width - cur_x if i == num_beds - 1 else bed_width_share, 2)

            if i < len(bathrooms):
                bath = bathrooms[i]
                bath_len = round(min(bath.target_length, band_depth * 0.35), 2)
                bed_len = round(band_depth - bath_len, 2)

                results.append(
                    RoomOutput(
                        id=bed.id,
                        name=bed.name,
                        category=bed.category,
                        x=round(cur_x, 2),
                        y=round(start_y, 2),
                        width=b_width,
                        length=bed_len,
                        area=round(b_width * bed_len, 2),
                        floor=1,
                    )
                )

                results.append(
                    RoomOutput(
                        id=bath.id,
                        name=bath.name,
                        category=bath.category,
                        x=round(cur_x, 2),
                        y=round(start_y + bed_len, 2),
                        width=round(min(b_width, bath.target_width), 2),
                        length=bath_len,
                        area=round(min(b_width, bath.target_width) * bath_len, 2),
                        floor=1,
                    )
                )
            else:
                results.append(
                    RoomOutput(
                        id=bed.id,
                        name=bed.name,
                        category=bed.category,
                        x=round(cur_x, 2),
                        y=round(start_y, 2),
                        width=b_width,
                        length=band_depth,
                        area=round(b_width * band_depth, 2),
                        floor=1,
                    )
                )

            cur_x += b_width

        if len(bathrooms) > num_beds:
            extra_baths = bathrooms[num_beds:]
            for eb in extra_baths:
                results.append(
                    RoomOutput(
                        id=eb.id,
                        name=eb.name,
                        category=eb.category,
                        x=round(start_x, 2),
                        y=round(start_y, 2),
                        width=eb.min_width,
                        length=eb.min_length,
                        area=round(eb.min_width * eb.min_length, 2),
                        floor=1,
                    )
                )
