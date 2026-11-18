import json
import urllib.request

payload = {
    "plot": {
        "plot_length": 65.0,
        "plot_width": 35.0,
        "front_width": 35.0,
        "unit": "feet",
        "entrance_orientation": "South",
    },
    "requirements": {
        "floors": 2,
        "parking": True,
        "ground_floor": {
            "bedrooms": 2,
            "bathrooms": 2,
            "kitchen": True,
            "living_room": True,
            "drawing_room": True,
        },
        "first_floor": {
            "bedrooms": 2,
            "bathrooms": 2,
            "living_room": True,
            "terrace": True,
        },
    },
}

req = urllib.request.Request(
    "http://127.0.0.1:5000/api/v1/plans/generate",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"},
)

with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read().decode())
    print("Status:", resp.status)
    print("Plan ID:", data.get("plan_id"))
    print("Floors count:", data.get("floors_count"))
    stair_val = data.get("staircase_validation", {})
    print("Staircase Validation valid:", stair_val.get("is_valid"))
    print("Flight type:", stair_val.get("flight_type"))
    print("Riser:", stair_val.get("unit_rise_inches"), "in | Tread:", stair_val.get("unit_tread_inches"), "in | Blondel:", stair_val.get("blondel_comfort_inches"))
    print("Headroom clearance:", stair_val.get("headroom_clearance_ft"), "ft")
    print("Directional indicators:", str(stair_val.get("directional_indicators")).encode('ascii', 'backslashreplace').decode('ascii'))
    print("Disclaimer:", stair_val.get("disclaimer")[:60] + "...")

    for fl in data.get("floor_layouts", []):
        print(f"\n--- Floor {fl['floor']} ({fl['name']}) ---")
        for r in fl["rooms"]:
            print(f"  - {r['name']} ({r['width']}x{r['length']} ft, {r['area']} sqft, cat: {r['category']})")
