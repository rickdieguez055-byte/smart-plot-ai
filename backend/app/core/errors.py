"""Custom exception classes and error structures for SmartPlot AI."""
from typing import Any, Dict, Optional


class SmartPlotAIException(Exception):
    """Base exception for SmartPlot AI module."""

    def __init__(self, message: str, code: str = "SMARTPLOT_ERROR", details: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details or {}


class SpatialInfeasibilityException(SmartPlotAIException):
    """Raised when user requirements cannot fit within plot dimensions."""

    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            code="SPATIAL_INFEASIBILITY",
            details=details,
        )


class PlotValidationException(SmartPlotAIException):
    """Raised when plot parameters are invalid."""

    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            code="INVALID_PLOT_INPUT",
            details=details,
        )
