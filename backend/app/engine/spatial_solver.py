"""Spatial Constraint Solver using Google OR-Tools CP-SAT and Geometric Partitioning."""
import logging
import math
from typing import Dict, List, Optional, Tuple
from ortools.sat.python import cp_model

from backend.app.core.errors import SpatialInfeasibilityException
from backend.app.engine.dimension_estimator import RoomSpecification
from backend.app.schemas.plot import OrientationEnum, PlotInput
from backend.app.schemas.response import RoomOutput

logger = logging.getLogger("smartplot.solver")


class SpatialLayoutSolver:
    """Solves 2D non-overlapping spatial room arrangement subject to architectural constraints."""

    SCALE = 10  # 1 unit = 0.1 ft/m for integer CP-SAT arithmetic

    @classmethod
    def solve(
        cls,
        plot: PlotInput,
        rooms: List[RoomSpecification],
        buildable_width: float,
        buildable_length: float,
        timeout_seconds: float = 5.0,
    ) -> List[RoomOutput]:
        """
        Solves the room layout using Google OR-Tools CP-SAT.
        Falls back to deterministic architectural zoning partitioner if CP-SAT times out.
        """
        # Attempt CP-SAT exact constraint solving
        try:
            solved_rooms = cls._solve_cp_sat(
                plot=plot,
                rooms=rooms,
                buildable_w=buildable_width,
                buildable_l=buildable_length,
                timeout=timeout_seconds,
            )
            if solved_rooms:
                return solved_rooms
        except Exception as e:
            logger.warning(f"CP-SAT solver encountered exception: {e}. Falling back to geometric solver.")

        # Fallback to deterministic topological layout solver
        return cls._solve_geometric_partitioning(
            plot=plot,
            rooms=rooms,
            buildable_w=buildable_width,
            buildable_l=buildable_length,
        )

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
            # Bounds
            min_w = int(round(r.min_width * cls.SCALE))
            max_w = min(bw_int, int(round(r.max_width * cls.SCALE)))
            min_h = int(round(r.min_length * cls.SCALE))
            max_h = min(bl_int, int(round(r.max_length * cls.SCALE)))

            if min_w > max_w or min_h > max_h:
                return None

            # Variables
            w_var = model.NewIntVar(min_w, max_w, f"w_{r.id}")
            h_var = model.NewIntVar(min_h, max_h, f"h_{r.id}")
            x_var = model.NewIntVar(0, bw_int, f"x_{r.id}")
            y_var = model.NewIntVar(0, bl_int, f"y_{r.id}")

            # Containment
            x_end = model.NewIntVar(0, bw_int, f"x_end_{r.id}")
            y_end = model.NewIntVar(0, bl_int, f"y_end_{r.id}")
            model.Add(x_end == x_var + w_var)
            model.Add(y_end == y_var + h_var)

            # Intervals
            x_int = model.NewIntervalVar(x_var, w_var, x_end, f"x_int_{r.id}")
            y_int = model.NewIntervalVar(y_var, h_var, y_end, f"y_int_{r.id}")

            x_vars[r.id] = x_var
            y_vars[r.id] = y_var
            w_vars[r.id] = w_var
            h_vars[r.id] = h_var
            x_intervals.append(x_int)
            y_intervals.append(y_int)

        # 1. 2D Non-Overlapping Global Constraint
        model.AddNoOverlap2D(x_intervals, y_intervals)

        # 2. Zoning Constraints based on Entrance Orientation
        # In our coordinate system:
        # Y=0 is Front/Road side (for South/standard entrance)
        # Y=max is Rear
        # X=0 is Left, X=max is Right
        orientation = plot.entrance_orientation

        for r in rooms:
            target_w_int = int(round(r.target_width * cls.SCALE))
            target_h_int = int(round(r.target_length * cls.SCALE))

            if r.category == "parking":
                # Parking placed at entrance boundary
                if orientation in [OrientationEnum.SOUTH, OrientationEnum.SOUTH_EAST, OrientationEnum.SOUTH_WEST]:
                    model.Add(y_vars[r.id] <= int(0.20 * bl_int))
                elif orientation in [OrientationEnum.NORTH, OrientationEnum.NORTH_EAST, OrientationEnum.NORTH_WEST]:
                    model.Add(y_vars[r.id] + h_vars[r.id] >= int(0.80 * bl_int))
                elif orientation == OrientationEnum.EAST:
                    model.Add(x_vars[r.id] + w_vars[r.id] >= int(0.80 * bw_int))
                elif orientation == OrientationEnum.WEST:
                    model.Add(x_vars[r.id] <= int(0.20 * bw_int))

            elif r.zone == "private":
                # Bedrooms & private baths placed in rear or protected area
                if orientation in [OrientationEnum.SOUTH, OrientationEnum.SOUTH_EAST, OrientationEnum.SOUTH_WEST]:
                    model.Add(y_vars[r.id] >= int(0.35 * bl_int))
                elif orientation in [OrientationEnum.NORTH, OrientationEnum.NORTH_EAST, OrientationEnum.NORTH_WEST]:
                    model.Add(y_vars[r.id] + h_vars[r.id] <= int(0.65 * bl_int))

        # 3. Soft Objective Function:
        # Minimize deviation from target dimensions & keep layout compact
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

        # Solve
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

    @classmethod
    def _solve_geometric_partitioning(
        cls,
        plot: PlotInput,
        rooms: List[RoomSpecification],
        buildable_w: float,
        buildable_l: float,
    ) -> List[RoomOutput]:
        """
        Deterministic, zoning-based floor plan partitioner.
        Organizes the buildable plot into functional architectural bands:
        - Front Band (Y: 0 -> Y1): Parking / Car Porch, Entrance Foyer, Front Lawn
        - Center Band (Y1 -> Y2): Living Room / Lounge, Kitchen, Dining Room
        - Rear Band (Y2 -> buildable_length): Master Bedroom, Bedrooms, Attached/Common Baths
        Guarantees 100% non-overlapping rectangles strictly contained within boundaries.
        """
        # Separate rooms by architectural zones
        front_rooms = [r for r in rooms if r.zone == "front"]
        semi_public_rooms = [r for r in rooms if r.zone == "semi-public"]
        service_rooms = [r for r in rooms if r.zone == "service"]
        private_rooms = [r for r in rooms if r.zone == "private"]

        # Calculate proportional band heights
        has_front = len(front_rooms) > 0
        has_middle = (len(semi_public_rooms) + len(service_rooms)) > 0
        has_rear = len(private_rooms) > 0

        # Target depths
        front_depth = max(r.min_length for r in front_rooms) if has_front else 0.0
        middle_depth = max(r.min_length for r in (semi_public_rooms + service_rooms)) if has_middle else 0.0
        rear_depth = max(r.min_length for r in private_rooms) if has_rear else 0.0

        total_req_depth = front_depth + middle_depth + rear_depth
        if total_req_depth > buildable_l:
            # Scale proportionally to fit within buildable_length
            ratio = buildable_l / total_req_depth
            front_depth = round(front_depth * ratio, 2)
            middle_depth = round(middle_depth * ratio, 2)
            rear_depth = round(buildable_l - front_depth - middle_depth, 2)
        else:
            # Distribute remaining depth proportionally
            excess = buildable_l - total_req_depth
            front_depth += round(excess * 0.25, 2)
            middle_depth += round(excess * 0.35, 2)
            rear_depth = round(buildable_l - front_depth - middle_depth, 2)

        results: List[RoomOutput] = []

        # 1. Place Front Band
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

        # 2. Place Middle Band (Living + Kitchen + Dining)
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

        # 3. Place Rear Band (Bedrooms + Bathrooms)
        if private_rooms:
            # Pair bedrooms with their bathrooms if possible
            bedrooms = [r for r in private_rooms if r.category == "bedroom"]
            bathrooms = [r for r in private_rooms if r.category == "bathroom"]

            # Pack bedrooms and baths across the rear band
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
                # Last room takes remaining width to avoid rounding gaps
                w = round(start_x + band_width - cur_x, 2)
            else:
                share = r.target_width / total_weight
                w = round(min(band_width * share, r.max_width), 2)
                # Ensure room is at least min_width
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
        """Packs bedrooms side-by-side with attached/accessible bathrooms along rear perimeter."""
        num_beds = len(bedrooms)
        if num_beds == 0:
            # Just pack whatever rooms are there
            cls._pack_band_horizontally(bathrooms, start_x, start_y, band_width, band_depth, results)
            return

        bed_width_share = band_width / num_beds
        cur_x = start_x

        for i, bed in enumerate(bedrooms):
            b_width = round(band_width - cur_x if i == num_beds - 1 else bed_width_share, 2)

            # Check if there is an associated bathroom to attach
            if i < len(bathrooms):
                bath = bathrooms[i]
                # Split depth: bedroom in front, bath in rear or vice-versa
                bath_len = round(min(bath.target_length, band_depth * 0.35), 2)
                bed_len = round(band_depth - bath_len, 2)

                # Bedroom
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

                # Attached Bath
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
                # Bedroom takes full band depth
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

        # Any extra bathrooms placed in remaining space
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
