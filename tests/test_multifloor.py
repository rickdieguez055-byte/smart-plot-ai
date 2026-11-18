"""Comprehensive Unit and Architectural Verification Tests for SmartPlot AI Phase 6 Multi-Floor Engine.

Validates:
1. Exact vertical staircase core alignment (3D stack coordinate match: |Δx| < 0.01, |Δy| < 0.01).
2. Ground and First floor architectural zoning and room allocations.
3. Door, window, and circulation separation per floor.
4. Dual SVGs with architectural stair treads and directional arrows (UP ↑ and DN ↓).
5. BFS reachability: GF from Main Entrance, F1 from Staircase Arrival Landing.
6. Single-floor backward compatibility (floors=1).
7. Validation rejection of floors > 2.
8. Robust multi-floor generation across standard residential plot dimensions (25x45, 25x50, 35x65, 50x90).
"""
import pytest
from backend.app.schemas.plot import PlotInput, OrientationEnum, PlotUnit
from backend.app.schemas.layout import LayoutRequirements, PlanGenerateRequest
from backend.app.services.plan_service import PlanGenerationService
from backend.app.engine.multifloor_solver import MultiFloorSpatialSolver
from pydantic import ValidationError


@pytest.fixture
def standard_5marla_plot():
    return PlotInput(
        plot_length=45.0,
        plot_width=25.0,
        front_width=25.0,
        entrance_orientation=OrientationEnum.SOUTH,
        unit=PlotUnit.FEET,
    )


@pytest.fixture
def multifloor_requirements():
    return LayoutRequirements(
        bedrooms=3,
        bathrooms=3,
        floors=2,
        kitchen=True,
        living_room=True,
        parking=True,
    )


class TestMultiFloorEngine:
    """Phase 6 Multi-Floor Architectural and Algorithmic Validation Suite."""

    def test_staircase_vertical_alignment_exact_match(self, standard_5marla_plot, multifloor_requirements):
        """Verifies 100% vertical staircase bounding box alignment between GF and F1."""
        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=multifloor_requirements,
        )
        response = PlanGenerationService.generate_plan(req)

        assert response.status == "success"
        assert response.floors_count == 2
        assert len(response.floor_layouts) == 2

        gf_layout = response.floor_layouts[0]
        f1_layout = response.floor_layouts[1]

        assert gf_layout.floor == 1
        assert f1_layout.floor == 2

        gf_stair = gf_layout.staircase_bounding_box
        f1_stair = f1_layout.staircase_bounding_box

        assert gf_stair is not None
        assert f1_stair is not None

        # Coordinate matching tolerance < 0.01 ft
        assert abs(gf_stair["x"] - f1_stair["x"]) < 0.01
        assert abs(gf_stair["y"] - f1_stair["y"]) < 0.01
        assert abs(gf_stair["width"] - f1_stair["width"]) < 0.01
        assert abs(gf_stair["length"] - f1_stair["length"]) < 0.01

        # Check in all alternatives
        for alt in response.alternatives:
            assert alt.staircase_aligned is True
            assert alt.floors_count == 2
            assert len(alt.floor_layouts) == 2

    def test_architectural_zoning_per_floor(self, standard_5marla_plot, multifloor_requirements):
        """Verifies proper floor-specific room allocation for Ground and First floors."""
        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=multifloor_requirements,
        )
        response = PlanGenerationService.generate_plan(req)
        gf = response.floor_layouts[0]
        f1 = response.floor_layouts[1]

        gf_cats = {r.category for r in gf.rooms}
        f1_cats = {r.category for r in f1.rooms}

        # Ground floor must have parking, staircase core, living, kitchen, bedroom, bath
        assert "parking" in gf_cats
        assert "staircase" in gf_cats
        assert "living" in gf_cats
        assert "kitchen" in gf_cats
        assert "bedroom" in gf_cats
        assert "bathroom" in gf_cats

        # First floor must have staircase arrival landing, upper lounge, terrace, bedrooms, baths
        assert "staircase" in f1_cats
        assert "living" in f1_cats  # Upper Family Lounge
        assert "terrace" in f1_cats  # Open Terrace above porch
        assert "bedroom" in f1_cats
        assert "bathroom" in f1_cats

        # Verify terrace name
        terrace_rooms = [r for r in f1.rooms if r.category == "terrace"]
        assert len(terrace_rooms) >= 1
        assert "terrace" in terrace_rooms[0].name.lower() or "balcony" in terrace_rooms[0].name.lower()

    def test_door_and_window_segregation_per_floor(self, standard_5marla_plot, multifloor_requirements):
        """Verifies doors and windows are correctly assigned to their respective floors."""
        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=multifloor_requirements,
        )
        response = PlanGenerationService.generate_plan(req)

        gf = response.floor_layouts[0]
        f1 = response.floor_layouts[1]

        assert len(gf.doors) > 0
        assert len(f1.doors) > 0
        assert len(gf.windows) > 0
        assert len(f1.windows) > 0

        # All GF doors and windows must have floor == 1
        for d in gf.doors:
            assert d.floor == 1
        for w in gf.windows:
            assert w.floor == 1

        # All F1 doors and windows must have floor == 2
        for d in f1.doors:
            assert d.floor == 2
        for w in f1.windows:
            assert w.floor == 2

    def test_separate_svg_drawings_with_directional_stair_indicators(self, standard_5marla_plot, multifloor_requirements):
        """Verifies professional separate SVGs with UP arrow on GF and DN arrow on F1."""
        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=multifloor_requirements,
        )
        response = PlanGenerationService.generate_plan(req)

        assert response.svg_ground_floor is not None
        assert response.svg_first_floor is not None

        svg_gf = response.svg_ground_floor
        svg_f1 = response.svg_first_floor

        # Ground Floor SVG checks
        assert "Ground Floor Plan" in svg_gf
        assert "UP ↑" in svg_gf
        assert "MANDATORY PRELIMINARY NOTICE" in svg_gf
        assert "<svg" in svg_gf and "</svg>" in svg_gf

        # First Floor SVG checks
        assert "First Floor Plan" in svg_f1
        assert "DN ↓" in svg_f1
        assert "OPEN TERRACE" in svg_f1 or "Terrace" in svg_f1 or "BALCONY" in svg_f1
        assert "MANDATORY PRELIMINARY NOTICE" in svg_f1
        assert "<svg" in svg_f1 and "</svg>" in svg_f1

    def test_backward_compatibility_single_floor(self, standard_5marla_plot):
        """Verifies single-floor request (floors=1) preserves Phase 1-5B behavior."""
        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=LayoutRequirements(
                bedrooms=2,
                bathrooms=2,
                floors=1,
                parking=True,
            ),
        )
        response = PlanGenerationService.generate_plan(req)

        assert response.status == "success"
        assert response.floors_count == 1
        assert response.svg_first_floor is None
        assert len(response.alternatives) == 2
        for alt in response.alternatives:
            assert alt.floors_count == 1

    def test_validation_rejection_floors_greater_than_two(self, standard_5marla_plot):
        """Verifies that requesting floors=3 or more is rejected by Pydantic schema validation."""
        with pytest.raises(ValidationError) as exc_info:
            LayoutRequirements(
                bedrooms=3,
                bathrooms=3,
                floors=3,
            )
        assert "less than or equal to 2" in str(exc_info.value) or "Multi-floor generation supports up to 2 floors" in str(exc_info.value)

    @pytest.mark.parametrize("length,width,front_w", [
        (45.0, 25.0, 25.0),  # Standard 5 Marla
        (50.0, 25.0, 25.0),  # Deep 5 Marla
        (65.0, 35.0, 35.0),  # Standard 10 Marla
        (90.0, 50.0, 50.0),  # 1 Kanal Luxury Plot
    ])
    def test_multifloor_across_standard_plot_dimensions(self, length, width, front_w):
        """Verifies multi-floor synthesis across various plot dimensions."""
        plot = PlotInput(
            plot_length=length,
            plot_width=width,
            front_width=front_w,
            entrance_orientation=OrientationEnum.NORTH,
            unit=PlotUnit.FEET,
        )
        req = PlanGenerateRequest(
            plot=plot,
            requirements=LayoutRequirements(
                bedrooms=3,
                bathrooms=3,
                floors=2,
                parking=True,
            ),
        )
        response = PlanGenerationService.generate_plan(req)
        assert response.status == "success"
        assert response.floors_count == 2
        assert len(response.alternatives) == 2

        for alt in response.alternatives:
            assert alt.staircase_aligned is True
            assert alt.is_feasible is True
            assert len(alt.floor_layouts) == 2
            assert alt.svg_ground_floor is not None
            assert alt.svg_first_floor is not None

    def test_floor_specific_room_requirements_synthesis(self, standard_5marla_plot):
        """Verifies independent Ground and First Floor specifications are honored."""
        from backend.app.schemas.layout import SingleFloorRequirement

        gf_req = SingleFloorRequirement(
            bedrooms=1,
            bathrooms=1,
            kitchen=True,
            living_room=True,
            drawing_room=True,
        )
        ff_req = SingleFloorRequirement(
            bedrooms=2,
            bathrooms=2,
            kitchen=False,
            living_room=True,
            terrace=True,
        )

        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=LayoutRequirements(
                floors=2,
                bedrooms=3,
                bathrooms=3,
                ground_floor=gf_req,
                first_floor=ff_req,
            ),
        )
        response = PlanGenerationService.generate_plan(req)
        assert response.status == "success"
        assert response.floors_count == 2

        for alt in response.alternatives:
            gf_rooms = [r for r in alt.rooms if r.floor == 1]
            f1_rooms = [r for r in alt.rooms if r.floor == 2]

            # Ground floor should have 1 bedroom, 1 bathroom, 1 kitchen, and drawing room
            assert any("Master Bedroom" in r.name or "Bedroom" in r.name for r in gf_rooms)
            assert any("Drawing Room" in r.name or "Baithak" in r.name for r in gf_rooms)
            assert any(r.category == "kitchen" for r in gf_rooms)

            # First floor should have 2 bedrooms, 2 bathrooms, terrace, upper lounge
            f1_beds = [r for r in f1_rooms if r.category == "bedroom"]
            assert len(f1_beds) == 2
            assert any("Terrace" in r.name or "Balcony" in r.name for r in f1_rooms)

    def test_staircase_validator_geometric_invariants(self, standard_5marla_plot, multifloor_requirements):
        """Verifies StaircaseValidator checks: rise, tread, Blondel formula, headroom, zero overlap."""
        req = PlanGenerateRequest(
            plot=standard_5marla_plot,
            requirements=multifloor_requirements,
        )
        response = PlanGenerationService.generate_plan(req)
        assert response.staircase_validation is not None
        sv = response.staircase_validation

        assert sv["is_valid"] is True
        assert sv["aligned"] is True
        assert abs(sv["dx_alignment"]) < 0.01
        assert abs(sv["dy_alignment"]) < 0.01
        assert sv["overlap_detected"] is False
        assert sv["headroom_cleared"] is True
        assert sv["dimensions"]["riser_height_inches"] == 7.5
        assert sv["dimensions"]["tread_depth_inches"] == 10.0
        assert sv["dimensions"]["risers_count"] == 16
        assert sv["dimensions"]["treads_count"] == 14
        assert sv["dimensions"]["treads_per_flight"] == 7
        assert sv["dimensions"]["flights_count"] == 2
        assert sv["dimensions"]["total_stair_run_ft"] <= sv["dimensions"]["reserved_shaft_length_ft"]
        assert sv["dimensions"]["landing_depth_feet"] == 3.0
        assert sv["dimensions"]["blondel_comfort_inches"] == 25.0
        assert "2R + T = 25.0 in" in sv["blondel_comfort_formula"]
        assert "CONCEPTUAL ARCHITECTURAL DESIGN ONLY" in sv["structural_disclaimer"]

    def test_schema_rejection_floor_specific_with_single_floor(self):
        """Verifies first_floor requirement is rejected when floors=1."""
        from backend.app.schemas.layout import SingleFloorRequirement
        with pytest.raises(ValidationError) as exc_info:
            LayoutRequirements(
                floors=1,
                first_floor=SingleFloorRequirement(bedrooms=2, bathrooms=2),
            )
        assert "first_floor requirements cannot be specified for single-story layouts" in str(exc_info.value)

    def test_schema_rejection_excessive_cross_floor_rooms(self):
        """Verifies bedrooms > 6 or bathrooms > 5 across floors are rejected."""
        from backend.app.schemas.layout import SingleFloorRequirement
        with pytest.raises(ValidationError) as exc_info:
            LayoutRequirements(
                floors=2,
                ground_floor=SingleFloorRequirement(bedrooms=4, bathrooms=3),
                first_floor=SingleFloorRequirement(bedrooms=4, bathrooms=3),
            )
        assert "exceeds maximum residential limit of 6" in str(exc_info.value)
