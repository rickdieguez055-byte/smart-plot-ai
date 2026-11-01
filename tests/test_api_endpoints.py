"""API Endpoint Integration Tests using FastAPI TestClient."""
import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.schemas.response import MANDATORY_DISCLAIMER

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "SmartPlot-AI"
    assert data["version"] == "1.0.0"


def test_generate_plan_valid():
    payload = {
        "plot": {
            "plot_length": 45.0,
            "plot_width": 25.0,
            "front_width": 25.0,
            "entrance_orientation": "South",
            "unit": "feet",
        },
        "requirements": {
            "bedrooms": 2,
            "bathrooms": 2,
            "floors": 1,
            "kitchen": True,
            "living_room": True,
            "parking": True,
        },
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 200
    data = response.json()

    assert data["status"] == "success"
    assert data["plan_id"].startswith("plan_")
    assert len(data["rooms"]) >= 6
    assert data["total_built_area"] > 0
    assert 0 < data["utilization_percentage"] <= 100
    assert "<svg" in data["svg_floor_plan"]
    assert len(data["recommendations"]) >= 3
    assert data["disclaimer"] == MANDATORY_DISCLAIMER


def test_generate_plan_invalid_negative_dimensions():
    payload = {
        "plot": {
            "plot_length": -45.0,
            "plot_width": 25.0,
            "front_width": 25.0,
            "entrance_orientation": "South",
        }
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["status"] == "error"
    assert data["code"] == "REQUEST_VALIDATION_ERROR"


def test_generate_plan_invalid_orientation():
    payload = {
        "plot": {
            "plot_length": 45.0,
            "plot_width": 25.0,
            "front_width": 25.0,
            "entrance_orientation": "Sideways",
        }
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["status"] == "error"


def test_generate_plan_impossible_requirements():
    payload = {
        "plot": {
            "plot_length": 15.0,
            "plot_width": 15.0,
            "front_width": 15.0,
            "entrance_orientation": "North",
        },
        "requirements": {
            "bedrooms": 5,
            "bathrooms": 4,
            "kitchen": True,
            "living_room": True,
            "parking": True,
        },
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["status"] == "error"
    assert data["code"] == "SPATIAL_INFEASIBILITY"
    assert "deficit" in data["details"]


def test_generate_plan_missing_required_fields():
    payload = {
        "plot": {
            "plot_length": 45.0
            # missing plot_width, front_width, entrance_orientation
        }
    }
    response = client.post("/api/v1/plans/generate", json=payload)
    assert response.status_code == 422
    data = response.json()
    assert data["status"] == "error"
