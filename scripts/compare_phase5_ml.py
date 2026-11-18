"""Comparative experimentation harness comparing Phase 4 CP-SAT vs Phase 5 Hybrid ML+CP-SAT."""
import json
import logging
import math
import os
import sys
import time
from typing import Dict, List, Tuple

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.ml.hybrid_solver import HybridSpatialSolver
from backend.app.schemas.layout import LayoutRequirements
from backend.app.schemas.plot import OrientationEnum, PlotInput, SetbackInput

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("smartplot.experiment")


def compute_manhattan_distance(r1, r2) -> float:
    c1_x = r1.x + r1.width / 2.0
    c1_y = r1.y + r1.length / 2.0
    c2_x = r2.x + r2.width / 2.0
    c2_y = r2.y + r2.length / 2.0
    return round(abs(c1_x - c2_x) + abs(c1_y - c2_y), 2)


def run_experiment_on_plot(
    name: str,
    plot: PlotInput,
    req: LayoutRequirements,
) -> Dict:
    logger.info(f"\n=======================================================")
    logger.info(f"Running Experiment: {name} ({plot.plot_width}x{plot.plot_length} ft)")
    logger.info(f"=======================================================")

    # 1. Run Baseline Phase 4 Solver (Rule-Based CP-SAT)
    t0 = time.time()
    baseline_plans = SpatialLayoutSolver.solve_alternatives(plot, req)
    t_baseline_ms = round((time.time() - t0) * 1000.0, 2)

    # 2. Run Phase 5 Hybrid ML + CP-SAT Solver
    t1 = time.time()
    hybrid_plans = HybridSpatialSolver.solve_alternatives(plot, req)
    t_hybrid_ms = round((time.time() - t1) * 1000.0, 2)

    def analyze_plan(plan, system_name):
        rooms = plan.rooms
        # Check critical functional pairs
        bed_bath_dist = []
        living_kitchen_dist = []

        beds = [r for r in rooms if r.category == "bedroom"]
        baths = [r for r in rooms if r.category == "bathroom"]
        living = next((r for r in rooms if r.category == "living"), None)
        kitchen = next((r for r in rooms if r.category == "kitchen"), None)

        if beds and baths:
            for b in beds:
                min_d = min(compute_manhattan_distance(b, bath) for bath in baths)
                bed_bath_dist.append(min_d)

        if living and kitchen:
            living_kitchen_dist.append(compute_manhattan_distance(living, kitchen))

        avg_bb_dist = round(sum(bed_bath_dist) / len(bed_bath_dist), 2) if bed_bath_dist else 0.0
        lk_dist = living_kitchen_dist[0] if living_kitchen_dist else 0.0

        return {
            "system": system_name,
            "layout_title": plan.title,
            "is_feasible": plan.is_feasible,
            "connectivity_verified": plan.connectivity_verified,
            "room_count": len(plan.rooms),
            "door_count": len(plan.doors),
            "window_count": len(plan.windows),
            "utilization_pct": plan.spatial_breakdown.utilization_percentage,
            "avg_bed_to_nearest_bath_dist_ft": avg_bb_dist,
            "living_kitchen_dist_ft": lk_dist,
        }

    plan_a_base = analyze_plan(baseline_plans[0], "Baseline CP-SAT")
    plan_a_hybrid = analyze_plan(hybrid_plans[0], "Hybrid ML+CP-SAT")

    plan_b_base = analyze_plan(baseline_plans[1], "Baseline CP-SAT")
    plan_b_hybrid = analyze_plan(hybrid_plans[1], "Hybrid ML+CP-SAT")

    result = {
        "plot_name": name,
        "plot_dimensions": f"{plot.plot_width}x{plot.plot_length}",
        "baseline_runtime_ms": t_baseline_ms,
        "hybrid_runtime_ms": t_hybrid_ms,
        "plan_a": {
            "baseline": plan_a_base,
            "hybrid": plan_a_hybrid,
        },
        "plan_b": {
            "baseline": plan_b_base,
            "hybrid": plan_b_hybrid,
        },
    }

    logger.info(f"Plan A (Open Living):")
    logger.info(f"  Baseline: Runtime={t_baseline_ms}ms, Feasible={plan_a_base['is_feasible']}, Bed-Bath Dist={plan_a_base['avg_bed_to_nearest_bath_dist_ft']}ft, LK Dist={plan_a_base['living_kitchen_dist_ft']}ft")
    logger.info(f"  Hybrid:   Runtime={t_hybrid_ms}ms, Feasible={plan_a_hybrid['is_feasible']}, Bed-Bath Dist={plan_a_hybrid['avg_bed_to_nearest_bath_dist_ft']}ft, LK Dist={plan_a_hybrid['living_kitchen_dist_ft']}ft")

    return result


def run_full_suite() -> List[Dict]:
    experiments = [
        (
            "5 Marla Standard (25x45)",
            PlotInput(
                plot_width=25.0,
                plot_length=45.0,
                front_width=25.0,
                entrance_orientation=OrientationEnum.NORTH,
                setbacks=SetbackInput(front=5.0, rear=3.0, left=0.0, right=0.0),
            ),
            LayoutRequirements(bedrooms=2, bathrooms=2, kitchen=True, living_room=True, parking=True, floors=1),
        ),
        (
            "5 Marla Modern (25x50)",
            PlotInput(
                plot_width=25.0,
                plot_length=50.0,
                front_width=25.0,
                entrance_orientation=OrientationEnum.NORTH,
                setbacks=SetbackInput(front=5.0, rear=4.0, left=0.0, right=0.0),
            ),
            LayoutRequirements(bedrooms=2, bathrooms=2, kitchen=True, living_room=True, parking=True, floors=1),
        ),
        (
            "10 Marla Luxury (35x65)",
            PlotInput(
                plot_width=35.0,
                plot_length=65.0,
                front_width=35.0,
                entrance_orientation=OrientationEnum.NORTH,
                setbacks=SetbackInput(front=7.0, rear=5.0, left=3.0, right=0.0),
            ),
            LayoutRequirements(bedrooms=3, bathrooms=3, kitchen=True, living_room=True, dining_room=True, parking=True, floors=1),
        ),
        (
            "1 Kanal Estate (50x90)",
            PlotInput(
                plot_width=50.0,
                plot_length=90.0,
                front_width=50.0,
                entrance_orientation=OrientationEnum.NORTH,
                setbacks=SetbackInput(front=10.0, rear=7.0, left=5.0, right=5.0),
            ),
            LayoutRequirements(bedrooms=3, bathrooms=3, kitchen=True, living_room=True, dining_room=True, parking=True, floors=1),
        ),
    ]

    all_results = []
    for name, plot, req in experiments:
        res = run_experiment_on_plot(name, plot, req)
        all_results.append(res)

    with open("docs/ML_EXPERIMENT_RESULTS.json", "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)

    logger.info("\nSaved full comparative results to docs/ML_EXPERIMENT_RESULTS.json")
    return all_results


if __name__ == "__main__":
    run_full_suite()
