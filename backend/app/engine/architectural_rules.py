"""Architectural Standards, Wall Thicknesses, Door/Window Sizing, and Connectivity Verification."""
from collections import deque
from dataclasses import dataclass
from typing import Dict, List, Optional, Set, Tuple

# Physical wall thickness standards in feet
EXT_WALL_THICKNESS = 0.75   # 9 inches (exterior brick/masonry wall)
INT_WALL_THICKNESS = 0.375  # 4.5 inches (interior partition brick wall)
MIN_CORRIDOR_WIDTH = 3.5    # 42 inches (standard minimum residential hallway)

# Door width standards in feet
MAIN_DOOR_WIDTH = 3.5       # 42 inches
BED_DOOR_WIDTH = 3.0        # 36 inches
BATH_DOOR_WIDTH = 2.5       # 30 inches
KITCHEN_DOOR_WIDTH = 3.0    # 36 inches

# Window width standards in feet
LIVING_WINDOW_WIDTH = 5.0
BED_WINDOW_WIDTH = 4.0
KITCHEN_WINDOW_WIDTH = 3.5
BATH_WINDOW_WIDTH = 2.0


@dataclass
class ConnectivityGraphResult:
    is_valid: bool
    reachable_rooms: Set[str]
    unreachable_rooms: Set[str]
    privacy_violations: List[str]
    error_message: Optional[str] = None


def verify_floor_plan_reachability(
    rooms: List[Dict],
    circulation_paths: List[Dict],
    doors: List[Dict],
    entrance_foyer_id: str = "foyer",
) -> ConnectivityGraphResult:
    """
    Verifies that every habitable room and bathroom is reachable from the entrance
    through valid circulation paths without passing through private rooms (unless reaching
    an attached en-suite bath).

    Graph Nodes:
      - Circulation paths / Foyers (public circulation)
      - Rooms
    Graph Edges:
      - Doors connecting (from_room, to_room)
    """
    # Build adjacency list
    adj: Dict[str, List[Tuple[str, str]]] = {}  # node -> [(neighbor, door_id)]

    all_nodes = set()
    for cp in circulation_paths:
        cid = cp["id"]
        adj[cid] = []
        all_nodes.add(cid)

    private_rooms: Set[str] = set()
    attached_baths: Dict[str, str] = {}  # bath_id -> parent_bedroom_id

    for r in rooms:
        rid = r["id"]
        adj[rid] = []
        all_nodes.add(rid)
        if r.get("category") == "bedroom":
            private_rooms.add(rid)
        elif r.get("category") == "bathroom" and "attached" in r.get("name", "").lower():
            # Will associate with parent bedroom via door
            pass

    for d in doors:
        u = d["from_room"]
        v = d["to_room"]
        if u not in adj:
            adj[u] = []
        if v not in adj:
            adj[v] = []
        adj[u].append((v, d["id"]))
        adj[v].append((u, d["id"]))

        # Check if this door connects a bedroom to an attached bath
        u_room = next((r for r in rooms if r["id"] == u), None)
        v_room = next((r for r in rooms if r["id"] == v), None)
        if u_room and v_room:
            if u_room.get("category") == "bedroom" and (v_room.get("category") == "bathroom" or "attached" in v_room.get("name", "").lower()):
                attached_baths[v] = u
            elif v_room.get("category") == "bedroom" and (u_room.get("category") == "bathroom" or "attached" in u_room.get("name", "").lower()):
                attached_baths[u] = v

    # Perform BFS from entrance_foyer_id or any circulation path
    start_node = entrance_foyer_id if entrance_foyer_id in adj else (
        circulation_paths[0]["id"] if circulation_paths else None
    )

    if not start_node:
        return ConnectivityGraphResult(
            is_valid=False,
            reachable_rooms=set(),
            unreachable_rooms={r["id"] for r in rooms},
            privacy_violations=[],
            error_message="No entrance foyer or circulation path defined.",
        )

    # Queue stores: (current_node, path_nodes_visited)
    queue = deque([(start_node, [start_node])])
    visited_nodes: Set[str] = {start_node}
    privacy_violations: List[str] = []

    while queue:
        curr, path = queue.popleft()

        for neighbor, door_id in adj.get(curr, []):
            if neighbor not in visited_nodes:
                # Privacy check: If we are traversing through a private bedroom
                # to reach anything other than its own attached bath, record violation!
                if curr in private_rooms:
                    if neighbor != attached_baths.get(neighbor) and attached_baths.get(neighbor) != curr:
                        # Traversing through bedroom to reach a non-attached room
                        privacy_violations.append(
                            f"Room '{neighbor}' is accessed by walking through private bedroom '{curr}'."
                        )

                visited_nodes.add(neighbor)
                queue.append((neighbor, path + [neighbor]))

    required_rooms = {r["id"] for r in rooms}
    reachable_rooms = visited_nodes.intersection(required_rooms)
    unreachable_rooms = required_rooms - reachable_rooms

    is_valid = (len(unreachable_rooms) == 0) and (len(privacy_violations) == 0)
    err = None
    if unreachable_rooms:
        err = f"Unreachable rooms without valid door/corridor connection: {unreachable_rooms}"
    elif privacy_violations:
        err = f"Privacy violations: {'; '.join(privacy_violations)}"

    return ConnectivityGraphResult(
        is_valid=is_valid,
        reachable_rooms=reachable_rooms,
        unreachable_rooms=unreachable_rooms,
        privacy_violations=privacy_violations,
        error_message=err,
    )
