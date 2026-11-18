"""Orchestration service for plot layout analysis and multi-alternative generation."""
import time
import uuid
from backend.app.core.config import settings
from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.engine.multifloor_solver import MultiFloorSpatialSolver
from backend.app.engine.recommendation_engine import RecommendationEngine
from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.ml.hybrid_solver import HybridSpatialSolver
from backend.app.renderer.svg_renderer import SVGFloorPlanRenderer
from backend.app.schemas.layout import PlanGenerateRequest
from backend.app.schemas.response import (
    MANDATORY_DISCLAIMER,
    PlanGenerateResponse,
    PlotDimensionsOutput,
)


class PlanGenerationService:
    """End-to-end floor plan generation producing multi-alternative architectural layouts."""

    @classmethod
    def generate_plan(cls, request: PlanGenerateRequest) -> PlanGenerateResponse:
        start_time = time.time()
        plan_id = f"plan_{uuid.uuid4().hex[:12]}"

        plot = request.plot
        req = request.requirements

        # 1. Feasibility analysis & dimension estimation
        rooms_specs, spatial_metrics = DimensionEstimator.estimate_rooms(plot, req)

        # 2. Generate Dual Architectural Alternatives using Hybrid ML + CP-SAT or MultiFloor Solver
        if req.floors == 2:
            alternatives = MultiFloorSpatialSolver.solve_multifloor_alternatives(
                plot=plot,
                req=req,
                timeout_seconds=settings.SOLVER_TIMEOUT_SECONDS,
            )
            total_plot_area = spatial_metrics["total_plot_area"]
            buildable_area = spatial_metrics["buildable_area"]

            for alt in alternatives:
                if not alt.recommendations:
                    alt.recommendations = RecommendationEngine.generate_recommendations(
                        plot=plot,
                        rooms=alt.rooms,
                        total_plot_area=total_plot_area,
                        total_built_area=round(sum(r.area for r in alt.rooms), 2),
                        utilization_percentage=alt.spatial_breakdown.utilization_percentage,
                        circulation_area=round(sum(cp.area for cp in alt.circulation_paths), 2),
                        windows=alt.windows,
                        doors=alt.doors,
                    )
        else:
            alternatives = HybridSpatialSolver.solve_alternatives(
                plot=plot,
                req=req,
                timeout_seconds=settings.SOLVER_TIMEOUT_SECONDS,
            )

            total_plot_area = spatial_metrics["total_plot_area"]
            buildable_area = spatial_metrics["buildable_area"]

            # 3. For each alternative, generate geometric recommendations and professional SVG
            for alt in alternatives:
                alt_built = round(sum(r.area for r in alt.rooms), 2)
                alt_circ = round(sum(cp.area for cp in alt.circulation_paths), 2)
                alt_util = alt.spatial_breakdown.utilization_percentage

                # Real geometric recommendations
                alt.recommendations = RecommendationEngine.generate_recommendations(
                    plot=plot,
                    rooms=alt.rooms,
                    total_plot_area=total_plot_area,
                    total_built_area=alt_built,
                    utilization_percentage=alt_util,
                    circulation_area=alt_circ,
                    windows=alt.windows,
                    doors=alt.doors,
                )

                # High-fidelity architectural SVG
                alt.svg_floor_plan = SVGFloorPlanRenderer.render(
                    plot=plot,
                    rooms=alt.rooms,
                    total_built_area=alt_built,
                    utilization_percentage=alt_util,
                    circulation_paths=alt.circulation_paths,
                    doors=alt.doors,
                    windows=alt.windows,
                    plan_title=f"SmartPlot — {alt.title}",
                    spatial_breakdown=alt.spatial_breakdown,
                )

        # Primary alternative is Plan A (maintaining backwards compatibility)
        primary = alternatives[0]
        total_built_area = primary.spatial_breakdown.net_room_area
        circulation_area = primary.spatial_breakdown.circulation_area
        utilization_percentage = primary.spatial_breakdown.utilization_percentage

        elapsed_ms = round((time.time() - start_time) * 1000.0, 2)

        plot_dimensions = PlotDimensionsOutput(
            length=plot.plot_length,
            width=plot.plot_width,
            front_width=plot.front_width,
            total_area=total_plot_area,
            buildable_area=buildable_area,
            unit=plot.unit.value,
            entrance_orientation=plot.entrance_orientation.value,
        )

        return PlanGenerateResponse(
            status="success",
            plan_id=plan_id,
            plot=plot_dimensions,
            rooms=primary.rooms,
            total_built_area=total_built_area,
            circulation_area=circulation_area,
            utilization_percentage=utilization_percentage,
            svg_floor_plan=primary.svg_floor_plan,
            recommendations=primary.recommendations,
            disclaimer=MANDATORY_DISCLAIMER,
            metadata={
                "solver_engine": "MultiFloorSpatialSolver" if req.floors == 2 else "OR-Tools-CP-SAT",
                "generation_mode": primary.generation_mode,
                "fallback_reason": primary.fallback_reason,
                "ml_model_version": getattr(HybridSpatialSolver, "model_version", "v2"),
                "scale_factor": spatial_metrics["scale_factor"],
                "execution_time_ms": elapsed_ms,
                "rooms_count": len(primary.rooms),
                "alternatives_count": len(alternatives),
                "floors_count": primary.floors_count,
            },
            spatial_breakdown=primary.spatial_breakdown,
            doors=primary.doors,
            windows=primary.windows,
            circulation_paths=primary.circulation_paths,
            alternatives=alternatives,
            floors_count=primary.floors_count,
            floor_layouts=primary.floor_layouts,
            svg_ground_floor=primary.svg_ground_floor,
            svg_first_floor=primary.svg_first_floor,
            staircase_validation=primary.staircase_validation,
        )
