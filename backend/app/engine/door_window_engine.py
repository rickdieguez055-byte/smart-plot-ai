"""Door and Window positioning engine with geometric wall-adjacency and exterior-wall checks."""
from typing import Dict, List, Optional, Tuple
from backend.app.engine.architectural_rules import (
    BATH_DOOR_WIDTH,
    BATH_WINDOW_WIDTH,
    BED_DOOR_WIDTH,
    BED_WINDOW_WIDTH,
    EXT_WALL_THICKNESS,
    KITCHEN_DOOR_WIDTH,
    KITCHEN_WINDOW_WIDTH,
    LIVING_WINDOW_WIDTH,
    MAIN_DOOR_WIDTH,
)
from backend.app.schemas.response import DoorOutput, WindowOutput


class DoorWindowEngine:
    """Computes exact doorway and exterior window positions on shared or perimeter walls."""

    @classmethod
    def generate_doors_and_windows(
        cls,
        rooms: List[Dict],
        circulation_paths: List[Dict],
        buildable_width: float,
        buildable_length: float,
        entrance_orientation: str = "South",
    ) -> Tuple[List[DoorOutput], List[WindowOutput]]:
        doors: List[DoorOutput] = []
        windows: List[WindowOutput] = []

        door_id_counter = 0
        window_id_counter = 0

        # All accessible targets (rooms + circulation passages)
        all_blocks = {r["id"]: r for r in rooms}
        all_blocks.update({cp["id"]: cp for cp in circulation_paths})

        # 1. Main Entrance Exterior Door
        # Connects front porch or main foyer to the road boundary
        front_passage = next((cp for cp in circulation_paths if "foyer" in cp["id"] or "porch" in cp["id"]), None)
        if not front_passage and circulation_paths:
            front_passage = circulation_paths[0]

        if front_passage:
            door_id_counter += 1
            main_door_x = round(front_passage["x"] + (front_passage["width"] / 2.0), 2)
            main_door_y = round(front_passage["y"], 2)
            doors.append(
                DoorOutput(
                    id=f"door_{door_id_counter}",
                    from_room="exterior",
                    to_room=front_passage["id"],
                    x=main_door_x,
                    y=main_door_y,
                    width=MAIN_DOOR_WIDTH,
                    wall="south" if entrance_orientation.lower() in ["south", "se", "sw"] else "north",
                    is_exterior=True,
                    swing="inward",
                )
            )

        # 2. Circulation Path Interconnections (e.g. Foyer to Hallway)
        for i in range(len(circulation_paths)):
            for j in range(i + 1, len(circulation_paths)):
                cp1 = circulation_paths[i]
                cp2 = circulation_paths[j]
                door_pos = cls._find_shared_wall_door(cp1, cp2, 3.0)
                if door_pos:
                    door_id_counter += 1
                    dx, dy, wall = door_pos
                    doors.append(
                        DoorOutput(
                            id=f"door_{door_id_counter}",
                            from_room=cp1["id"],
                            to_room=cp2["id"],
                            x=dx,
                            y=dy,
                            width=3.5,
                            wall=wall,
                            is_exterior=False,
                            swing="inward",
                        )
                    )

        # 3. Interior Doors: Connect each room to a corridor, foyer, or parent suite
        for r in rooms:
            rid = r["id"]
            rcat = r.get("category", "")
            rname = r.get("name", "").lower()

            target_door_width = BED_DOOR_WIDTH
            if rcat == "bathroom":
                target_door_width = BATH_DOOR_WIDTH
            elif rcat == "kitchen":
                target_door_width = KITCHEN_DOOR_WIDTH
            elif rcat == "living":
                target_door_width = MAIN_DOOR_WIDTH

            # If this is an attached bath, it must connect directly to its assigned bedroom
            if rcat == "bathroom" and "attached" in rname:
                parent_bed = next(
                    (other for other in rooms if other.get("category") == "bedroom" and "master" in other.get("name", "").lower()),
                    None
                )
                if not parent_bed:
                    parent_bed = next((other for other in rooms if other.get("category") == "bedroom"), None)

                if parent_bed:
                    door_pos = cls._find_shared_wall_door(r, parent_bed, target_door_width)
                    if door_pos:
                        door_id_counter += 1
                        dx, dy, wall = door_pos
                        doors.append(
                            DoorOutput(
                                id=f"door_{door_id_counter}",
                                from_room=parent_bed["id"],
                                to_room=rid,
                                x=dx,
                                y=dy,
                                width=target_door_width,
                                wall=wall,
                                is_exterior=False,
                                swing="inward",
                            )
                        )
                        continue

            # Standard room: Connect to adjacent circulation paths
            connected = False
            for cp in circulation_paths:
                door_pos = cls._find_shared_wall_door(r, cp, target_door_width)
                if door_pos:
                    door_id_counter += 1
                    dx, dy, wall = door_pos
                    doors.append(
                        DoorOutput(
                            id=f"door_{door_id_counter}",
                            from_room=cp["id"],
                            to_room=rid,
                            x=dx,
                            y=dy,
                            width=target_door_width,
                            wall=wall,
                            is_exterior=False,
                            swing="inward",
                        )
                    )
                    connected = True
                    # If this is not a central living room, one circulation connection is sufficient
                    if rcat != "living":
                        break

            # Fallback for bathrooms connecting to adjacent bedrooms as attached ensuites
            if not connected and rcat == "bathroom":
                for other_id, other in all_blocks.items():
                    if other_id != rid and other.get("category") == "bedroom":
                        door_pos = cls._find_shared_wall_door(r, other, target_door_width)
                        if door_pos:
                            door_id_counter += 1
                            dx, dy, wall = door_pos
                            doors.append(
                                DoorOutput(
                                    id=f"door_{door_id_counter}",
                                    from_room=other_id,
                                    to_room=rid,
                                    x=dx,
                                    y=dy,
                                    width=target_door_width,
                                    wall=wall,
                                    is_exterior=False,
                                    swing="inward",
                                )
                            )
                            connected = True
                            break

            # Fallback for open rooms or porch connecting to living room/foyer
            if not connected:
                # Find any adjacent room that is not a private bedroom
                for other_id, other in all_blocks.items():
                    if other_id != rid and other.get("category") not in ["bedroom", "bathroom"]:
                        door_pos = cls._find_shared_wall_door(r, other, target_door_width)
                        if door_pos:
                            door_id_counter += 1
                            dx, dy, wall = door_pos
                            doors.append(
                                DoorOutput(
                                    id=f"door_{door_id_counter}",
                                    from_room=other_id,
                                    to_room=rid,
                                    x=dx,
                                    y=dy,
                                    width=target_door_width,
                                    wall=wall,
                                    is_exterior=False,
                                    swing="inward",
                                )
                            )
                            connected = True
                            break

        # 3. Verified Exterior Windows
        # Check every room for perimeter exterior walls
        for r in rooms:
            rid = r["id"]
            rcat = r.get("category", "")
            rx, ry = r["x"], r["y"]
            rw, rl = r["width"], r["length"]

            w_width = BED_WINDOW_WIDTH
            if rcat == "living":
                w_width = LIVING_WINDOW_WIDTH
            elif rcat == "kitchen":
                w_width = KITCHEN_WINDOW_WIDTH
            elif rcat == "bathroom":
                w_width = BATH_WINDOW_WIDTH

            # Check South exterior wall (front)
            if ry <= EXT_WALL_THICKNESS + 0.5:
                window_id_counter += 1
                windows.append(
                    WindowOutput(
                        id=f"win_{window_id_counter}",
                        room_id=rid,
                        x=round(rx + (rw / 2.0), 2),
                        y=round(ry, 2),
                        width=min(w_width, rw * 0.7),
                        wall="south",
                        exterior_facing="front",
                    )
                )

            # Check North exterior wall (rear)
            if ry + rl >= buildable_length - EXT_WALL_THICKNESS - 0.5:
                window_id_counter += 1
                windows.append(
                    WindowOutput(
                        id=f"win_{window_id_counter}",
                        room_id=rid,
                        x=round(rx + (rw / 2.0), 2),
                        y=round(ry + rl, 2),
                        width=min(w_width, rw * 0.7),
                        wall="north",
                        exterior_facing="rear",
                    )
                )

            # Check West exterior wall (left)
            if rx <= EXT_WALL_THICKNESS + 0.5:
                window_id_counter += 1
                windows.append(
                    WindowOutput(
                        id=f"win_{window_id_counter}",
                        room_id=rid,
                        x=round(rx, 2),
                        y=round(ry + (rl / 2.0), 2),
                        width=min(w_width, rl * 0.6),
                        wall="west",
                        exterior_facing="left",
                    )
                )

            # Check East exterior wall (right)
            if rx + rw >= buildable_width - EXT_WALL_THICKNESS - 0.5:
                window_id_counter += 1
                windows.append(
                    WindowOutput(
                        id=f"win_{window_id_counter}",
                        room_id=rid,
                        x=round(rx + rw, 2),
                        y=round(ry + (rl / 2.0), 2),
                        width=min(w_width, rl * 0.6),
                        wall="east",
                        exterior_facing="right",
                    )
                )

        return doors, windows

    @classmethod
    def _find_shared_wall_door(
        cls, r1: Dict, r2: Dict, door_width: float, tol: float = 0.5
    ) -> Optional[Tuple[float, float, str]]:
        """
        Determines if r1 and r2 share a physical wall segment long enough to fit a door.
        Returns: (door_x, door_y, wall_orientation_from_r1_perspective)
        """
        x1, y1, w1, l1 = r1["x"], r1["y"], r1["width"], r1["length"]
        x2, y2, w2, l2 = r2["x"], r2["y"], r2["width"], r2["length"]

        # Case 1: R1's East wall touches R2's West wall
        if abs((x1 + w1) - x2) <= tol:
            overlap_y_start = max(y1, y2)
            overlap_y_end = min(y1 + l1, y2 + l2)
            if (overlap_y_end - overlap_y_start) >= door_width:
                mid_y = round((overlap_y_start + overlap_y_end) / 2.0, 2)
                return (round(x2, 2), mid_y, "east")

        # Case 2: R1's West wall touches R2's East wall
        if abs(x1 - (x2 + w2)) <= tol:
            overlap_y_start = max(y1, y2)
            overlap_y_end = min(y1 + l1, y2 + l2)
            if (overlap_y_end - overlap_y_start) >= door_width:
                mid_y = round((overlap_y_start + overlap_y_end) / 2.0, 2)
                return (round(x1, 2), mid_y, "west")

        # Case 3: R1's North wall touches R2's South wall
        if abs((y1 + l1) - y2) <= tol:
            overlap_x_start = max(x1, x2)
            overlap_x_end = min(x1 + w1, x2 + w2)
            if (overlap_x_end - overlap_x_start) >= door_width:
                mid_x = round((overlap_x_start + overlap_x_end) / 2.0, 2)
                return (mid_x, round(y2, 2), "north")

        # Case 4: R1's South wall touches R2's North wall
        if abs(y1 - (y2 + l2)) <= tol:
            overlap_x_start = max(x1, x2)
            overlap_x_end = min(x1 + w1, x2 + w2)
            if (overlap_x_end - overlap_x_start) >= door_width:
                mid_x = round((overlap_x_start + overlap_x_end) / 2.0, 2)
                return (mid_x, round(y1, 2), "south")

        return None
