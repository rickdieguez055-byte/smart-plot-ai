"""Architectural dimension estimator and spatial feasibility analyzer."""
from dataclasses import dataclass
from typing import Dict, List, Tuple
from backend.app.core.errors import SpatialInfeasibilityException
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import PlotInput, PlotUnit


@dataclass
class RoomSpecification:
    id: str
    name: str
    category: str
    min_width: float
    max_width: float
    min_length: float
    max_length: float
    target_width: float
    target_length: float
    target_area: float
    priority: int  # 1 (critical) to 5 (optional)
    zone: str      # 'front', 'semi-public', 'service', 'private'


class DimensionEstimator:
    """Estimates appropriate architectural dimensions for rooms based on plot size and standards."""

    # Standard residential dimensions in FEET
    STANDARD_SPECS = {
        "master_bedroom": {
            "name": "Master Bedroom",
            "category": "bedroom",
            "min_w": 11.0, "max_w": 16.0, "min_l": 12.0, "max_l": 18.0,
            "target_w": 12.0, "target_l": 14.0, "zone": "private", "priority": 1,
        },
        "bedroom": {
            "name": "Bedroom",
            "category": "bedroom",
            "min_w": 9.5, "max_w": 14.0, "min_l": 10.0, "max_l": 15.0,
            "target_w": 11.0, "target_l": 12.5, "zone": "private", "priority": 2,
        },
        "master_bath": {
            "name": "Attached Bath",
            "category": "bathroom",
            "min_w": 4.5, "max_w": 8.0, "min_l": 6.0, "max_l": 9.0,
            "target_w": 5.0, "target_l": 7.0, "zone": "private", "priority": 2,
        },
        "bath": {
            "name": "Bath",
            "category": "bathroom",
            "min_w": 4.0, "max_w": 7.0, "min_l": 5.5, "max_l": 8.0,
            "target_w": 4.5, "target_l": 6.5, "zone": "private", "priority": 3,
        },
        "kitchen": {
            "name": "Kitchen",
            "category": "kitchen",
            "min_w": 7.0, "max_w": 12.0, "min_l": 8.0, "max_l": 14.0,
            "target_w": 8.5, "target_l": 10.5, "zone": "service", "priority": 1,
        },
        "living_room": {
            "name": "Living Room & Lounge",
            "category": "living",
            "min_w": 11.0, "max_w": 18.0, "min_l": 12.0, "max_l": 22.0,
            "target_w": 13.0, "target_l": 16.0, "zone": "semi-public", "priority": 1,
        },
        "car_porch": {
            "name": "Car Porch & Parking",
            "category": "parking",
            "min_w": 9.5, "max_w": 14.0, "min_l": 13.5, "max_l": 20.0,
            "target_w": 10.5, "target_l": 15.0, "zone": "front", "priority": 2,
        },
        "dining_room": {
            "name": "Dining Room",
            "category": "living",
            "min_w": 8.5, "max_w": 13.0, "min_l": 9.5, "max_l": 15.0,
            "target_w": 10.0, "target_l": 11.5, "zone": "semi-public", "priority": 3,
        },
        "store_room": {
            "name": "Store Room",
            "category": "utility",
            "min_w": 4.5, "max_w": 7.0, "min_l": 5.0, "max_l": 8.0,
            "target_w": 5.0, "target_l": 6.0, "zone": "service", "priority": 4,
        },
    }

    # Meter conversion factor (1 meter = 3.28084 feet)
    M_TO_FT = 3.28084
    FT_TO_M = 1.0 / 3.28084

    @classmethod
    def estimate_rooms(
        cls, plot: PlotInput, req: LayoutRequirements
    ) -> Tuple[List[RoomSpecification], Dict[str, float]]:
        """
        Builds the room list and verifies feasibility against buildable plot area.
        Returns:
            Tuple of (List of RoomSpecification, spatial_metrics dict)
        Raises:
            SpatialInfeasibilityException if plot cannot accommodate the rooms.
        """
        # 1. Normalize dimensions to feet internally
        is_meters = plot.unit == PlotUnit.METERS
        factor = cls.M_TO_FT if is_meters else 1.0

        p_len_ft = plot.plot_length * factor
        p_wid_ft = plot.plot_width * factor

        # Deduct setbacks if provided
        sb_front = (plot.setbacks.front * factor) if plot.setbacks else 0.0
        sb_rear = (plot.setbacks.rear * factor) if plot.setbacks else 0.0
        sb_left = (plot.setbacks.left * factor) if plot.setbacks else 0.0
        sb_right = (plot.setbacks.right * factor) if plot.setbacks else 0.0

        buildable_len_ft = max(0.0, p_len_ft - sb_front - sb_rear)
        buildable_wid_ft = max(0.0, p_wid_ft - sb_left - sb_right)
        buildable_area_ft2 = buildable_len_ft * buildable_wid_ft

        if buildable_len_ft < 10.0 or buildable_wid_ft < 10.0:
            raise SpatialInfeasibilityException(
                message=f"Buildable plot dimensions ({buildable_wid_ft:.1f}x{buildable_len_ft:.1f} ft) after setbacks are too small for residential layout.",
                details={
                    "buildable_width": buildable_wid_ft / factor,
                    "buildable_length": buildable_len_ft / factor,
                    "unit": plot.unit.value,
                },
            )

        # 2. Determine plot scale factor (e.g., compact 5-marla vs medium 10-marla vs 1-kanal)
        total_plot_area_ft2 = p_len_ft * p_wid_ft
        if total_plot_area_ft2 <= 1300.0:
            # Compact (<= 5 marla)
            scale = 0.90
        elif total_plot_area_ft2 <= 2500.0:
            # Medium (7 to 10 marla)
            scale = 1.00
        else:
            # Spacious (> 10 marla)
            scale = 1.15

        # 3. Assemble required room list
        rooms: List[RoomSpecification] = []
        room_counter = 0

        # Parking / Porch
        if req.parking:
            room_counter += 1
            spec = cls._make_spec("car_porch", f"room_{room_counter}", "Car Porch & Parking", scale, factor, is_meters)
            rooms.append(spec)

        # Living Room
        if req.living_room:
            room_counter += 1
            spec = cls._make_spec("living_room", f"room_{room_counter}", "Living Room & Lounge", scale, factor, is_meters)
            rooms.append(spec)

        # Kitchen
        if req.kitchen:
            room_counter += 1
            spec = cls._make_spec("kitchen", f"room_{room_counter}", "Kitchen", scale, factor, is_meters)
            rooms.append(spec)

        # Dining Room
        if req.dining_room:
            room_counter += 1
            spec = cls._make_spec("dining_room", f"room_{room_counter}", "Dining Room", scale, factor, is_meters)
            rooms.append(spec)

        # Bedrooms
        for b in range(1, req.bedrooms + 1):
            room_counter += 1
            key = "master_bedroom" if b == 1 else "bedroom"
            label = "Master Bedroom" if b == 1 else f"Bedroom {b}"
            spec = cls._make_spec(key, f"room_{room_counter}", label, scale, factor, is_meters)
            rooms.append(spec)

        # Bathrooms
        for bt in range(1, req.bathrooms + 1):
            room_counter += 1
            key = "master_bath" if bt == 1 else "bath"
            label = "Attached Bath" if bt == 1 else f"Bath {bt}"
            spec = cls._make_spec(key, f"room_{room_counter}", label, scale, factor, is_meters)
            rooms.append(spec)

        # Store Room
        if req.store_room:
            room_counter += 1
            spec = cls._make_spec("store_room", f"room_{room_counter}", "Store Room", scale, factor, is_meters)
            rooms.append(spec)

        # 4. Infeasibility analysis
        # Total minimum area needed
        total_min_area = sum(r.min_width * r.min_length for r in rooms)
        # Add 15% allowance for walls and internal circulation corridors
        required_with_circulation = total_min_area * 1.15

        actual_buildable_area = buildable_area_ft2 / (factor * factor)

        if required_with_circulation > actual_buildable_area:
            deficit = required_with_circulation - actual_buildable_area
            raise SpatialInfeasibilityException(
                message=(
                    f"Requested rooms require at least {required_with_circulation:.1f} {plot.unit.value}² "
                    f"(including circulation), but buildable area is only {actual_buildable_area:.1f} {plot.unit.value}². "
                    f"Deficit: {deficit:.1f} {plot.unit.value}²."
                ),
                details={
                    "required_minimum_area": round(required_with_circulation, 1),
                    "buildable_area": round(actual_buildable_area, 1),
                    "deficit": round(deficit, 1),
                    "room_count": len(rooms),
                    "unit": plot.unit.value,
                    "suggestion": "Reduce the number of bedrooms/bathrooms or consider adding a second floor.",
                },
            )

        metrics = {
            "buildable_width": buildable_wid_ft / factor,
            "buildable_length": buildable_len_ft / factor,
            "buildable_area": actual_buildable_area,
            "total_plot_area": (p_len_ft * p_wid_ft) / (factor * factor),
            "scale_factor": scale,
        }
        return rooms, metrics

    @classmethod
    def _make_spec(
        cls, key: str, room_id: str, label: str, scale: float, factor: float, is_meters: bool
    ) -> RoomSpecification:
        std = cls.STANDARD_SPECS[key]
        unit_scale = 1.0 / factor if is_meters else 1.0

        min_w = round(std["min_w"] * scale * unit_scale, 2)
        max_w = round(std["max_w"] * scale * unit_scale, 2)
        min_l = round(std["min_l"] * scale * unit_scale, 2)
        max_l = round(std["max_l"] * scale * unit_scale, 2)

        target_w = round(std["target_w"] * scale * unit_scale, 2)
        target_l = round(std["target_l"] * scale * unit_scale, 2)
        target_area = round(target_w * target_l, 2)

        return RoomSpecification(
            id=room_id,
            name=label,
            category=std["category"],
            min_width=min_w,
            max_width=max_w,
            min_length=min_l,
            max_length=max_l,
            target_width=target_w,
            target_length=target_l,
            target_area=target_area,
            priority=std["priority"],
            zone=std["zone"],
        )
