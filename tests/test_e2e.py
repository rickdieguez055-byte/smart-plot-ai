"""End-to-End Pipeline Integration Test.
Tests the full request flow:
Client -> Node.js API Gateway (5000) -> Python/FastAPI Microservice (8000) -> Output.
"""
import time
import httpx
import pytest

GATEWAY_URL = "http://127.0.0.1:5000"
FASTAPI_URL = "http://127.0.0.1:8000"


def is_service_up(url: str) -> bool:
    try:
        r = httpx.get(f"{url}/health", timeout=2.0)
        return r.status_code == 200
    except Exception:
        return False


@pytest.mark.skipif(
    not (is_service_up(GATEWAY_URL) and is_service_up(FASTAPI_URL)),
    reason="Both Gateway and FastAPI microservice must be running for live E2E test",
)
def test_live_end_to_end_pipeline():
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

    response = httpx.post(f"{GATEWAY_URL}/api/v1/plans/generate", json=payload, timeout=10.0)
    assert response.status_code == 200
    data = response.json()

    assert data["status"] == "success"
    assert "plan_id" in data
    assert len(data["rooms"]) >= 6
    assert "<svg" in data["svg_floor_plan"]
    assert "preliminary" in data["disclaimer"].lower()
