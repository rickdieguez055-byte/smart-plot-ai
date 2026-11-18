"""Dataset loading, parsing, and tabular pair generation from real ResPlan floor plans."""
import json
import logging
import os
from collections import Counter
from typing import Dict, List, Optional, Set, Tuple

import pandas as pd

from backend.app.ml.features import FloorPlanGraph, RoomEntity, extract_pair_features
from backend.app.ml.taxonomy import map_room_label

logger = logging.getLogger("smartplot.ml.dataset")


def compute_polygon_area(points: List[List[float]]) -> float:
    """Calculates polygon area using the Shoelace formula."""
    if not points or len(points) < 3:
        return 0.0
    n = len(points)
    area = 0.0
    for i in range(n):
        j = (i + 1) % n
        area += points[i][0] * points[j][1]
        area -= points[j][0] * points[i][1]
    return abs(area) / 2.0


def parse_plan_dict(d: Dict) -> Optional[FloorPlanGraph]:
    """Parses a raw ResPlan record into a FloorPlanGraph."""
    gt = d.get("gt")
    if not gt or "rooms" not in gt or "walls" not in gt:
        return None

    plan_id = d.get("id", "unknown")
    raw_rooms = gt["rooms"]
    walls = {w["id"]: w for w in gt["walls"]}

    if len(raw_rooms) < 2:
        return None

    # Parse room entities
    rooms: List[RoomEntity] = []
    min_x, max_x = float("inf"), float("-inf")
    min_y, max_y = float("inf"), float("-inf")

    for idx, r in enumerate(raw_rooms):
        raw_label = r.get("label", "ROOM")
        category = map_room_label(raw_label)
        poly = r.get("polygon", [])
        area = compute_polygon_area(poly)
        if area <= 0.0:
            area = 100.0  # reasonable fallback for zero/missing polygon

        for pt in poly:
            min_x = min(min_x, pt[0])
            max_x = max(max_x, pt[0])
            min_y = min(min_y, pt[1])
            max_y = max(max_y, pt[1])

        rooms.append(
            RoomEntity(
                id=f"{plan_id}_r{idx}",
                raw_label=raw_label,
                category=category,
                area=area,
                polygon=poly,
                walls=r.get("walls", []),
            )
        )

    # Determine bounding box
    if min_x == float("inf"):
        bounding_w, bounding_l = 100.0, 100.0
    else:
        bounding_w = max(10.0, max_x - min_x)
        bounding_l = max(10.0, max_y - min_y)

    total_area = sum(r.area for r in rooms)

    # Compute ground truth adjacencies and door connections
    adjacencies: Set[Tuple[int, int]] = set()
    door_connections: Set[Tuple[int, int]] = set()

    n = len(rooms)
    for i in range(n):
        walls_i = set(rooms[i].walls or [])
        for j in range(i + 1, n):
            walls_j = set(rooms[j].walls or [])
            shared_walls = walls_i.intersection(walls_j)
            if shared_walls:
                adjacencies.add((i, j))
                # Check for door openings on any shared wall
                has_door = False
                for wid in shared_walls:
                    w = walls.get(wid)
                    if w and any(op.get("type") == "door" for op in w.get("openings", [])):
                        has_door = True
                        break
                if has_door:
                    door_connections.add((i, j))

    return FloorPlanGraph(
        plan_id=plan_id,
        bounding_width=bounding_w,
        bounding_length=bounding_l,
        total_area=total_area,
        rooms=rooms,
        adjacencies=adjacencies,
        door_connections=door_connections,
    )


def load_resplan_split(
    file_path: str,
    max_plans: Optional[int] = None,
) -> List[FloorPlanGraph]:
    """Loads and parses floor plans from a JSONL split file."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"ResPlan split not found at: {file_path}")

    plans: List[FloorPlanGraph] = []
    with open(file_path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f):
            if max_plans is not None and len(plans) >= max_plans:
                break
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                parsed = parse_plan_dict(record)
                if parsed:
                    plans.append(parsed)
            except Exception as e:
                logger.debug(f"Skipping malformed line {idx}: {e}")

    logger.info(f"Loaded {len(plans)} floor plans from {file_path}")
    return plans


def build_pairwise_dataframe(plans: List[FloorPlanGraph]) -> pd.DataFrame:
    """Converts a collection of floor plans into a tabular pairwise ML dataset."""
    rows = []

    for plan in plans:
        rooms = plan.rooms
        n = len(rooms)
        room_counts = Counter(r.category for r in rooms)

        for i in range(n):
            for j in range(i + 1, n):
                r1 = rooms[i]
                r2 = rooms[j]

                is_adj = 1 if (i, j) in plan.adjacencies else 0
                is_conn = 1 if (i, j) in plan.door_connections else 0

                feat = extract_pair_features(
                    r1=r1,
                    r2=r2,
                    total_rooms=n,
                    plot_width=plan.bounding_width,
                    plot_length=plan.bounding_length,
                    total_area=plan.total_area,
                    room_counts=room_counts,
                )

                feat["plan_id"] = plan.plan_id
                feat["room1_id"] = r1.id
                feat["room2_id"] = r2.id
                feat["is_adjacent"] = is_adj
                feat["is_connected"] = is_conn

                rows.append(feat)

    df = pd.DataFrame(rows)
    return df
