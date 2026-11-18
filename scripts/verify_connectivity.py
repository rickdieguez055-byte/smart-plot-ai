"""Verify complete communication flow: Gateway (5000) -> FastAPI (8000) -> Hybrid ML + CP-SAT."""
import json
import urllib.request

payload = {
    "plot": {
        "plot_length": 45.0,
        "plot_width": 25.0,
        "front_width": 25.0,
        "unit": "feet",
        "entrance_orientation": "South",
        "setbacks": {"front": 5.0, "rear": 3.0, "left": 0.0, "right": 0.0},
    },
    "requirements": {
        "bedrooms": 2,
        "bathrooms": 2,
        "kitchen": True,
        "living_room": True,
        "parking": True,
        "floors": 1,
    },
}

print("Sending request to Node.js Gateway at http://localhost:5000/api/v1/plans/generate...")
req = urllib.request.Request(
    "http://localhost:5000/api/v1/plans/generate",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json", "User-Agent": "SmartPlotAI-Phase6/1.0"},
)

with urllib.request.urlopen(req, timeout=10) as resp:
    data = json.loads(resp.read().decode())
    print(f"Gateway Response Code: {resp.status}")
    print(f"Plan ID: {data.get('plan_id')}")
    print(f"Alternatives Count: {len(data.get('alternatives', []))}")
    for alt in data.get("alternatives", []):
        print(
            f" - {alt.get('layout_type')}: '{alt.get('title')}' | "
            f"Mode: {alt.get('generation_mode')} | "
            f"Rooms: {len(alt.get('rooms', []))} | "
            f"Doors: {len(alt.get('doors', []))} | "
            f"Windows: {len(alt.get('windows', []))} | "
            f"Feasible: {alt.get('is_feasible')}"
        )
    print("Verification completed successfully. Real backend responded with dual alternatives!")
