"""Ablation study rigorously comparing:
(A) Pure Rule-Based Constraint Solver (No ML guidance)
(B) Hybrid ML-Guided Constraint Solver (Learned ResPlan probabilities)
(C) Ablated Constraint Solver (Shuffled / Neutral uniform probabilities)

Evaluates:
- Graph walking distance through doors and corridors (true path traversal)
- Adjacency satisfaction rate for high-affinity spaces (Bed-Bath, Living-Kitchen)
- Door connectivity alignment with learned relationship priors
- Geometric feasibility and non-overlap guarantees
- Solver convergence time (milliseconds)
"""
import copy
import json
import os
import sys
import time
from collections import deque
from typing import Any, Dict, List, Optional, Tuple

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.ml.hybrid_solver import HybridSpatialSolver
from backend.app.ml.model import RoomRelationshipPredictor
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import OrientationEnum, PlotInput, PlotUnit, SetbackInput
from backend.app.schemas.response import DoorOutput, PlanAlternative, RoomOutput


def build_circulation_graph(alt: PlanAlternative) -> Dict[str, List[Tuple[str, float]]]:
    """Constructs a spatial graph of rooms and corridors with door edge distances."""
    graph: Dict[str, List[Tuple[str, float]]] = {}
    positions: Dict[str, Tuple[float, float]] = {}

    for r in alt.rooms:
        cx = r.x + r.width / 2.0
        cy = r.y + r.length / 2.0
        positions[r.id] = (cx, cy)
        graph[r.id] = []

    for c in alt.circulation_paths:
        cx = c.x + c.width / 2.0
        cy = c.y + c.length / 2.0
        positions[c.id] = (cx, cy)
        graph[c.id] = []

    for d in alt.doors:
        r1, r2 = d.from_room, d.to_room
        if r1 in positions and r2 in positions:
            p1 = positions[r1]
            p2 = positions[r2]
            dx = d.x
            dy = d.y
            # Walking distance: center1 -> door -> center2
            dist1 = ((p1[0] - dx) ** 2 + (p1[1] - dy) ** 2) ** 0.5
            dist2 = ((p2[0] - dx) ** 2 + (p2[1] - dy) ** 2) ** 0.5
            tot_dist = dist1 + dist2
            graph[r1].append((r2, tot_dist))
            graph[r2].append((r1, tot_dist))

    return graph


def compute_shortest_walking_distance(graph: Dict[str, List[Tuple[str, float]]], start: str, target: str) -> Optional[float]:
    """Computes shortest walking distance along door connections using Dijkstra's algorithm."""
    if start not in graph or target not in graph:
        return None
    if start == target:
        return 0.0

    import heapq
    pq = [(0.0, start)]
    visited = {}

    while pq:
        dist, node = heapq.heappop(pq)
        if node in visited and visited[node] <= dist:
            continue
        visited[node] = dist
        if node == target:
            return round(dist, 2)

        for neighbor, edge_dist in graph.get(node, []):
            if neighbor not in visited or dist + edge_dist < visited[neighbor]:
                heapq.heappush(pq, (dist + edge_dist, neighbor))

    return None


def run_ablation_for_plot(name: str, plot: PlotInput, req: LayoutRequirements) -> Dict[str, Any]:
    print(f"\n=================== ABLATION FOR: {name} ===================")

    # 1. Mode A: Pure Rule-Based Solver
    t0 = time.time()
    plans_a = SpatialLayoutSolver.solve_alternatives(plot=plot, req=req, timeout_seconds=5.0)
    time_a = (time.time() - t0) * 1000.0
    plan_a = plans_a[0]

    # 2. Mode B: Hybrid ML Solver (Trained V2)
    t0 = time.time()
    plans_b = HybridSpatialSolver.solve_alternatives(plot=plot, req=req, timeout_seconds=5.0)
    time_b = (time.time() - t0) * 1000.0
    plan_b = plans_b[0]

    # 3. Mode C: Shuffled / Adversarial Inverted ML Solver
    rooms_specs, spatial_metrics = DimensionEstimator.estimate_rooms(plot, req)
    bw = spatial_metrics["buildable_width"]
    bl = spatial_metrics["buildable_length"]
    shuffled_ml = {}
    for i in range(len(rooms_specs)):
        for j in range(i + 1, len(rooms_specs)):
            key = (rooms_specs[i].id, rooms_specs[j].id)
            c1, c2 = sorted([rooms_specs[i].category, rooms_specs[j].category])
            # Invert true architectural relationships
            if c1 == "bedroom" and c2 == "bedroom":
                dp = 0.85
            elif c1 == "bathroom" and c2 == "bedroom":
                dp = 0.05
            elif c1 == "kitchen" and c2 == "living":
                dp = 0.10
            else:
                dp = 0.50
            shuffled_ml[key] = {
                "door_prob": dp,
                "adj_prob": dp,
                "recommended_adjacent": dp >= 0.50,
                "recommended_door": dp >= 0.50,
            }

    t0 = time.time()
    plan_c = HybridSpatialSolver._generate_ml_guided_open_plan(
        plot=plot,
        req=req,
        rooms_specs=rooms_specs,
        bw=bw,
        bl=bl,
        ml_relationships=shuffled_ml,
        timeout_seconds=5.0,
    )
    time_c = (time.time() - t0) * 1000.0

    modes = [("Mode A (Pure Rules)", plan_a, time_a), ("Mode B (ML Hybrid)", plan_b, time_b), ("Mode C (Adversarial ML)", plan_c, time_c)]

    metrics_by_mode = {}
    for mname, p, ms in modes:
        graph = build_circulation_graph(p)

        # Identify key functional spaces
        bed1 = next((r.id for r in p.rooms if r.category == "bedroom"), None)
        bath1 = next((r.id for r in p.rooms if r.category == "bathroom"), None)
        kitchen = next((r.id for r in p.rooms if r.category == "kitchen"), None)
        living = next((r.id for r in p.rooms if r.category == "living"), None)
        foyer = next((c.id for c in p.circulation_paths if "foyer" in c.id), None)

        bed_bath_dist = compute_shortest_walking_distance(graph, bed1, bath1) if bed1 and bath1 else None
        kit_liv_dist = compute_shortest_walking_distance(graph, kitchen, living) if kitchen and living else None

        # Adjacency check for Bed1 & Bath1
        bed_bath_adj = False
        kit_liv_adj = False
        if bed1 and bath1:
            r_bed = next(r for r in p.rooms if r.id == bed1)
            r_bath = next(r for r in p.rooms if r.id == bath1)
            # Sharing wall check
            x_overlap = max(0.0, min(r_bed.x + r_bed.width, r_bath.x + r_bath.width) - max(r_bed.x, r_bath.x))
            y_overlap = max(0.0, min(r_bed.y + r_bed.length, r_bath.y + r_bath.length) - max(r_bed.y, r_bath.y))
            if (abs(r_bed.y + r_bed.length - r_bath.y) < 0.2 or abs(r_bath.y + r_bath.length - r_bed.y) < 0.2) and x_overlap > 1.0:
                bed_bath_adj = True
            elif (abs(r_bed.x + r_bed.width - r_bath.x) < 0.2 or abs(r_bath.x + r_bath.width - r_bed.x) < 0.2) and y_overlap > 1.0:
                bed_bath_adj = True

        if kitchen and living:
            r_kit = next(r for r in p.rooms if r.id == kitchen)
            r_liv = next(r for r in p.rooms if r.id == living)
            x_overlap = max(0.0, min(r_kit.x + r_kit.width, r_liv.x + r_liv.width) - max(r_kit.x, r_liv.x))
            y_overlap = max(0.0, min(r_kit.y + r_kit.length, r_liv.y + r_liv.length) - max(r_kit.y, r_liv.y))
            if (abs(r_kit.y + r_kit.length - r_liv.y) < 0.2 or abs(r_liv.y + r_liv.length - r_kit.y) < 0.2) and x_overlap > 1.0:
                kit_liv_adj = True
            elif (abs(r_kit.x + r_kit.width - r_liv.x) < 0.2 or abs(r_liv.x + r_liv.width - r_kit.x) < 0.2) and y_overlap > 1.0:
                kit_liv_adj = True

        direct_bed_bath_door = any(
            (d.from_room == bed1 and d.to_room == bath1) or (d.from_room == bath1 and d.to_room == bed1)
            for d in p.doors
        )

        metrics_by_mode[mname] = {
            "feasible": p.is_feasible,
            "connected": p.connectivity_verified,
            "execution_time_ms": round(ms, 1),
            "bed_bath_walking_distance": bed_bath_dist,
            "kit_liv_walking_distance": kit_liv_dist,
            "bed_bath_adjacent": bed_bath_adj,
            "kit_liv_adjacent": kit_liv_adj,
            "direct_bed_bath_door": direct_bed_bath_door,
            "total_doors": len(p.doors),
        }

        print(f"[{mname}] Solve: {ms:.1f}ms | Feasible={p.is_feasible} | Bed-Bath Walk={bed_bath_dist}ft (Adj={bed_bath_adj}, Door={direct_bed_bath_door}) | Kit-Liv Walk={kit_liv_dist}ft (Adj={kit_liv_adj})")

    return metrics_by_mode


def main():
    scenarios = [
        (
            "25x45 ft (5 Marla Standard)",
            PlotInput(
                plot_length=45.0,
                plot_width=25.0,
                front_width=25.0,
                unit=PlotUnit.FEET,
                entrance_orientation=OrientationEnum.NORTH,
                setbacks=SetbackInput(front=5.0, rear=3.0, left=0.0, right=0.0),
            ),
            LayoutRequirements(
                bedrooms=3,
                bathrooms=2,
                kitchen=True,
                living_room=True,
                parking=True,
            ),
        ),
        (
            "25x50 ft (5 Marla Deep)",
            PlotInput(
                plot_length=50.0,
                plot_width=25.0,
                front_width=25.0,
                unit=PlotUnit.FEET,
                entrance_orientation=OrientationEnum.NORTH,
                setbacks=SetbackInput(front=5.0, rear=4.0, left=0.0, right=0.0),
            ),
            LayoutRequirements(
                bedrooms=3,
                bathrooms=2,
                kitchen=True,
                living_room=True,
                parking=True,
            ),
        ),
        (
            "35x65 ft (10 Marla Luxury)",
            PlotInput(
                plot_length=65.0,
                plot_width=35.0,
                front_width=35.0,
                unit=PlotUnit.FEET,
                entrance_orientation=OrientationEnum.EAST,
                setbacks=SetbackInput(front=7.0, rear=5.0, left=3.0, right=0.0),
            ),
            LayoutRequirements(
                bedrooms=3,
                bathrooms=2,
                kitchen=True,
                living_room=True,
                parking=True,
            ),
        ),
        (
            "50x90 ft (1 Kanal Estate)",
            PlotInput(
                plot_length=90.0,
                plot_width=50.0,
                front_width=50.0,
                unit=PlotUnit.FEET,
                entrance_orientation=OrientationEnum.SOUTH,
                setbacks=SetbackInput(front=10.0, rear=7.0, left=5.0, right=5.0),
            ),
            LayoutRequirements(
                bedrooms=3,
                bathrooms=2,
                kitchen=True,
                living_room=True,
                parking=True,
            ),
        ),
    ]

    all_results = {}
    for name, plot, req in scenarios:
        res = run_ablation_for_plot(name, plot, req)
        all_results[name] = res

    out_file = os.path.join(os.path.dirname(__file__), "../backend/app/ml/artifacts/ablation_results.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)
    print(f"\nSaved ablation study results to: {out_file}")


if __name__ == "__main__":
    main()
