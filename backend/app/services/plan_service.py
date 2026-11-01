"""Orchestration service for plot layout analysis and generation."""
import time
import uuid
from backend.app.core.config import settings
from backend.app.engine.dimension_estimator import DimensionEstimator
from backend.app.engine.recommendation_engine import RecommendationEngine
from backend.app.engine.spatial_solver import SpatialLayoutSolver
from backend.app.renderer.svg_renderer import SVGFloorPlanRenderer
from backend.app.schemas.layout import PlanGenerateRequest
from backend.app.schemas.response import (
    MANDATORY_DISCLAIMER,
    PlanGenerateResponse,
    PlotDimensionsOutput,
)


class PlanGenerationService:
    """End-to-end floor plan generation and plot analysis pipeline."""

    @classmethod
    def generate_plan(cls, request: PlanGenerateRequest) -> PlanGenerateResponse:
        start_time = time.time()
        plan_id = f"plan_{uuid.uuid4().hex[:12]}"

        plot = request.plot
        req = request.requirements

        # 1. Architectural dimension estimation and feasibility check
        rooms_specs, spatial_metrics = DimensionEstimator.estimate_rooms(plot, req)

        # 2. Spatial layout solving (OR-Tools CP-SAT + Geometric fallback)
        solved_rooms = SpatialLayoutSolver.solve(
            plot=plot,
            rooms=rooms_specs,
            buildable_width=spatial_metrics["buildable_width"],
            buildable_length=spatial_metrics["buildable_length"],
            timeout_seconds=settings.SOLVER_TIMEOUT_SECONDS,
        )

        # 3. Calculate spatial metrics
        total_plot_area = spatial_metrics["total_plot_area"]
        buildable_area = spatial_metrics["buildable_area"]
        total_built_area = round(sum(r.area for r in solved_rooms), 2)
        circulation_area = round(max(0.0, buildable_area - total_built_area), 2)
        utilization_percentage = round((total_built_area / total_plot_area) * 100.0, 1)

        # 4. Location-specific and orientation recommendations
        recommendations = RecommendationEngine.generate_recommendations(
            plot=plot,
            rooms=solved_rooms,
            total_plot_area=total_plot_area,
            total_built_area=total_built_area,
            utilization_percentage=utilization_percentage,
        )

        # 5. Render 2D SVG floor plan
        svg_floor_plan = SVGFloorPlanRenderer.render(
            plot=plot,
            rooms=solved_rooms,
            total_built_area=total_built_area,
            utilization_percentage=utilization_percentage,
        )

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
            rooms=solved_rooms,
            total_built_area=total_built_area,
            circulation_area=circulation_area,
            utilization_percentage=utilization_percentage,
            svg_floor_plan=svg_floor_plan,
            recommendations=recommendations,
            disclaimer=MANDATORY_DISCLAIMER,
            metadata={
                "solver_engine": "OR-Tools-CP-SAT",
                "scale_factor": spatial_metrics["scale_factor"],
                "execution_time_ms": elapsed_ms,
                "rooms_count": len(solved_rooms),
            },
        )
