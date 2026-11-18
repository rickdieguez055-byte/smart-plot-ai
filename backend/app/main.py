"""FastAPI Application entrypoint for SmartPlot AI Microservice."""
import logging
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.app.core.config import settings
from backend.app.core.errors import PlotValidationException, SpatialInfeasibilityException
from backend.app.schemas.layout import PlanGenerateRequest
from backend.app.schemas.response import ErrorResponse, PlanGenerateResponse
from backend.app.schemas.edit import PlanEditValidationRequest, PlanEditValidationResponse
from backend.app.services.plan_service import PlanGenerationService
from backend.app.engine.interactive_editor import InteractivePlanEditor

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("smartplot.api")

app = FastAPI(
    title=settings.APP_NAME,
    description=(
        "SmartPlot AI Microservice for automated residential plot analysis, "
        "spatial constraint-solving, and 2D floor-plan generation (SP-AI-01 to SP-AI-14)."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception Handlers
@app.exception_handler(SpatialInfeasibilityException)
async def spatial_infeasibility_handler(request: Request, exc: SpatialInfeasibilityException):
    logger.warning(f"Spatial Infeasibility: {exc.message} | Details: {exc.details}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=ErrorResponse(
            status="error",
            code=exc.code,
            message=exc.message,
            details=exc.details,
        ).model_dump(),
    )


@app.exception_handler(PlotValidationException)
async def plot_validation_handler(request: Request, exc: PlotValidationException):
    logger.warning(f"Plot Validation Error: {exc.message}")
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content=ErrorResponse(
            status="error",
            code=exc.code,
            message=exc.message,
            details=exc.details,
        ).model_dump(),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        field = " -> ".join(str(loc) for loc in err.get("loc", []))
        errors.append({"field": field, "message": err.get("msg")})
    logger.warning(f"Validation error on {request.url.path}: {errors}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=ErrorResponse(
            status="error",
            code="REQUEST_VALIDATION_ERROR",
            message="Supplied request parameters failed validation.",
            details={"validation_errors": errors},
        ).model_dump(),
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled server error on {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            status="error",
            code="INTERNAL_SERVER_ERROR",
            message="An unexpected error occurred during layout generation. Please verify inputs and retry.",
            details={"error_type": type(exc).__name__},
        ).model_dump(),
    )


# Endpoints
@app.get("/health", tags=["System"])
async def health_check():
    """Service health and diagnostic status."""
    return {
        "status": "ok",
        "service": settings.APP_NAME,
        "version": "1.0.0",
        "environment": settings.APP_ENV,
    }


@app.post(
    "/api/v1/plans/generate",
    response_model=PlanGenerateResponse,
    status_code=status.HTTP_200_OK,
    tags=["Layout Generation"],
    summary="Generate 2D Floor Plan from Plot Dimensions and Requirements",
)
async def generate_plan(request: PlanGenerateRequest):
    """
    Core AI Plot Analysis & Layout Generation endpoint (SP-AI-01 through SP-AI-10).
    - Accepts plot dimensions (length, width, front width, entrance orientation).
    - Evaluates architectural room requirements.
    - Solves 2D non-overlapping room arrangement using OR-Tools CP-SAT.
    - Produces location-specific environmental recommendations.
    - Renders proportionally scaled 2D SVG floor plan.
    - Attaches mandatory preliminary design notice.
    """
    logger.info(
        f"Plan generation request: {request.plot.plot_width}x{request.plot.plot_length} {request.plot.unit.value}, "
        f"entrance={request.plot.entrance_orientation.value}, "
        f"beds={request.requirements.bedrooms if request.requirements else 2}"
    )
    return PlanGenerationService.generate_plan(request)


@app.post(
    "/api/v1/plans/validate-edit",
    response_model=PlanEditValidationResponse,
    status_code=status.HTTP_200_OK,
    tags=["Interactive Plan Editing"],
    summary="Validate User-Modified Room Geometry in Real-Time",
)
async def validate_plan_edit(request: PlanEditValidationRequest):
    """
    Validates user-modified room geometry against boundary containment,
    no-overlap, minimum dimensions, staircase alignment, and circulation reachability.
    """
    logger.info(
        f"Plan edit validation request: Floor {request.floor}/{request.floors_count}, "
        f"{len(request.rooms)} rooms on {request.plot.plot_width}x{request.plot.plot_length} plot."
    )
    return InteractivePlanEditor.validate_and_apply_edit(request)


@app.post(
    "/api/v1/plans/apply-edit",
    response_model=PlanEditValidationResponse,
    status_code=status.HTTP_200_OK,
    tags=["Interactive Plan Editing"],
    summary="Apply Validated Plan Edit and Regenerate Layout Elements",
)
async def apply_plan_edit(request: PlanEditValidationRequest):
    """
    Validates and applies user edits, recalculating doors, windows, walls,
    and dynamically regenerating the 2D SVG floor plan drawing.
    """
    logger.info(
        f"Apply plan edit request: Floor {request.floor}/{request.floors_count}, "
        f"{len(request.rooms)} rooms."
    )
    return InteractivePlanEditor.validate_and_apply_edit(request)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host=settings.APP_HOST, port=settings.APP_PORT, reload=settings.DEBUG)
