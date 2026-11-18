"""Script to generate verified sample floor plans for Phase 2 verification."""
import os
import sys

# Add project root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.schemas.plot import PlotInput
from backend.app.schemas.layout import LayoutRequirements, PlanGenerateRequest
from backend.app.services.plan_service import PlanGenerationService

DOCS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs"))

TEST_CASES = [
    {
        "name": "25x45",
        "desc": "Standard 5 Marla Plot (25x45 ft / 125 sq yd)",
        "plot": PlotInput(
            plot_length=45.0,
            plot_width=25.0,
            front_width=25.0,
            entrance_orientation="South",
            unit="feet",
        ),
        "requirements": LayoutRequirements(
            bedrooms=2,
            bathrooms=2,
            kitchen=True,
            living_room=True,
            parking=True,
        ),
    },
    {
        "name": "25x50",
        "desc": "Modern 5 Marla Plot (25x50 ft / 138.8 sq yd)",
        "plot": PlotInput(
            plot_length=50.0,
            plot_width=25.0,
            front_width=25.0,
            entrance_orientation="South",
            unit="feet",
        ),
        "requirements": LayoutRequirements(
            bedrooms=3,
            bathrooms=2,
            kitchen=True,
            living_room=True,
            parking=True,
        ),
    },
    {
        "name": "35x65",
        "desc": "Executive 10 Marla Plot (35x65 ft / 250 sq yd)",
        "plot": PlotInput(
            plot_length=65.0,
            plot_width=35.0,
            front_width=35.0,
            entrance_orientation="South",
            unit="feet",
        ),
        "requirements": LayoutRequirements(
            bedrooms=3,
            bathrooms=3,
            kitchen=True,
            living_room=True,
            parking=True,
        ),
    },
    {
        "name": "50x90",
        "desc": "Spacious 1 Kanal Plot (50x90 ft / 500 sq yd)",
        "plot": PlotInput(
            plot_length=90.0,
            plot_width=50.0,
            front_width=50.0,
            entrance_orientation="South",
            unit="feet",
        ),
        "requirements": LayoutRequirements(
            bedrooms=4,
            bathrooms=4,
            kitchen=True,
            living_room=True,
            parking=True,
        ),
    },
]

def main():
    print("=== Generating Phase 2 Verified Architectural SVG Floor Plans ===")
    os.makedirs(DOCS_DIR, exist_ok=True)

    for tc in TEST_CASES:
        name = tc["name"]
        print(f"\n--- Processing {tc['desc']} ---")
        req_obj = PlanGenerateRequest(plot=tc["plot"], requirements=tc["requirements"])
        res = PlanGenerationService.generate_plan(req_obj)
        
        print(f"Total Alternatives Generated: {len(res.alternatives)}")
        
        for idx, alt in enumerate(res.alternatives):
            plan_code = "plan_a" if alt.layout_type == "open_living" else "plan_b"
            file_name = f"sample_{name}_{plan_code}.svg"
            file_path = os.path.join(DOCS_DIR, file_name)
            
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(alt.svg_floor_plan)
                
            print(f"  [OK] {alt.title} -> {file_name}")
            print(f"    - Rooms: {len(alt.rooms)}, Doors: {len(alt.doors)}, Windows: {len(alt.windows)}")
            print(f"    - Feasible: {alt.is_feasible}, Connectivity Verified: {alt.connectivity_verified}")
            print(f"    - Covered Area: {alt.spatial_breakdown.total_covered_area} sq ft ({alt.spatial_breakdown.utilization_percentage}%)")
            print(f"    - Net Rooms: {alt.spatial_breakdown.net_room_area} sq ft, Circulation: {alt.spatial_breakdown.circulation_area} sq ft, Walls: {alt.spatial_breakdown.wall_area} sq ft")

    print("\nAll sample architectural SVG plans generated successfully!")

if __name__ == "__main__":
    main()
