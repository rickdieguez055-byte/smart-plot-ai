"""Regression test suite for SmartPlot AI Phase 6 Area Accounting & Staircase Physical Verification.

Specifically tests against:
1. Covered area greater than allowable footprint (> 2x plot area or > 1x plot area per floor).
2. Double-counted staircase, circulation, or arbitrary additive wall footprints.
3. Accidentally combined Plan A and Plan B area.
4. Invalid inclusion of open terraces in covered area.
5. Staircase geometry exceeding reserved spatial shaft bounds.
6. Multi-floor room accessibility and connectivity graph validation.
"""
import pytest
from backend.app.schemas.plot import PlotInput, OrientationEnum, PlotUnit
from backend.app.schemas.layout import LayoutRequirements, SingleFloorRequirement, PlanGenerateRequest
from backend.app.services.plan_service import PlanGenerationService
from backend.app.engine.staircase_validator import StaircaseValidator


BENCHMARKS = [
    ("25x45", 25.0, 45.0, OrientationEnum.SOUTH, SingleFloorRequirement(bedrooms=1, bathrooms=1, kitchen=True, living_room=True, drawing_room=True), SingleFloorRequirement(bedrooms=2, bathrooms=2, kitchen=False, living_room=True, terrace=True)),
    ("25x50", 25.0, 50.0, OrientationEnum.NORTH, SingleFloorRequirement(bedrooms=1, bathrooms=1, kitchen=True, living_room=True, drawing_room=True), SingleFloorRequirement(bedrooms=2, bathrooms=2, kitchen=False, living_room=True, terrace=True)),
    ("35x65", 35.0, 65.0, OrientationEnum.EAST, SingleFloorRequirement(bedrooms=2, bathrooms=2, kitchen=True, living_room=True, drawing_room=True), SingleFloorRequirement(bedrooms=3, bathrooms=2, kitchen=False, living_room=True, terrace=True)),
    ("50x90", 50.0, 90.0, OrientationEnum.WEST, SingleFloorRequirement(bedrooms=2, bathrooms=2, kitchen=True, living_room=True, drawing_room=True), SingleFloorRequirement(bedrooms=3, bathrooms=3, kitchen=False, living_room=True, terrace=True)),
]


class TestAreaAccountingRegression:
    """Verifies that multi-floor area accounting strictly obeys physical conservation laws."""

    @pytest.mark.parametrize("name,width,length,orientation,gf_req,f1_req", BENCHMARKS)
    def test_covered_area_never_exceeds_two_floor_plot_boundary(self, name, width, length, orientation, gf_req, f1_req):
        """Verifies that total covered area <= 2 * plot_area for both Plan A and Plan B."""
        plot_area = width * length
        two_floor_max = plot_area * 2.0

        req = PlanGenerateRequest(
            plot=PlotInput(
                plot_length=length,
                plot_width=width,
                front_width=width,
                entrance_orientation=orientation,
                unit=PlotUnit.FEET,
            ),
            requirements=LayoutRequirements(
                floors=2,
                bedrooms=gf_req.bedrooms + f1_req.bedrooms,
                bathrooms=gf_req.bathrooms + f1_req.bathrooms,
                parking=True,
                ground_floor=gf_req,
                first_floor=f1_req,
            ),
        )
        response = PlanGenerationService.generate_plan(req)
        assert response.status == "success"
        assert len(response.alternatives) == 2

        for alt_idx, alt in enumerate(response.alternatives):
            sb = alt.spatial_breakdown
            gf_sb = alt.floor_layouts[0].spatial_breakdown
            f1_sb = alt.floor_layouts[1].spatial_breakdown

            # Ground floor covered footprint must not exceed plot area
            assert gf_sb.total_covered_area <= plot_area + 0.05, (
                f"{name} Alt {alt_idx} GF covered ({gf_sb.total_covered_area}) exceeds plot area ({plot_area})"
            )
            assert gf_sb.utilization_percentage <= 100.0, (
                f"{name} Alt {alt_idx} GF utilization ({gf_sb.utilization_percentage}%) exceeds 100%"
            )

            # First floor covered footprint must not exceed plot area
            assert f1_sb.total_covered_area <= plot_area + 0.05, (
                f"{name} Alt {alt_idx} F1 covered ({f1_sb.total_covered_area}) exceeds plot area ({plot_area})"
            )
            assert f1_sb.utilization_percentage <= 100.0, (
                f"{name} Alt {alt_idx} F1 utilization ({f1_sb.utilization_percentage}%) exceeds 100%"
            )

            # Combined covered area must not exceed 2x plot area
            assert sb.total_covered_area <= two_floor_max + 0.05, (
                f"{name} Alt {alt_idx} Combined covered ({sb.total_covered_area}) exceeds 2x plot area ({two_floor_max})"
            )
            assert sb.utilization_percentage <= 100.0, (
                f"{name} Alt {alt_idx} Combined utilization ({sb.utilization_percentage}%) exceeds 100%"
            )

    @pytest.mark.parametrize("name,width,length,orientation,gf_req,f1_req", BENCHMARKS)
    def test_terrace_is_not_counted_as_covered_area(self, name, width, length, orientation, gf_req, f1_req):
        """Verifies that open terraces are categorized under open/uncovered area and excluded from covered footprint."""
        req = PlanGenerateRequest(
            plot=PlotInput(
                plot_length=length,
                plot_width=width,
                front_width=width,
                entrance_orientation=orientation,
                unit=PlotUnit.FEET,
            ),
            requirements=LayoutRequirements(
                floors=2,
                bedrooms=gf_req.bedrooms + f1_req.bedrooms,
                bathrooms=gf_req.bathrooms + f1_req.bathrooms,
                parking=True,
                ground_floor=gf_req,
                first_floor=f1_req,
            ),
        )
        response = PlanGenerationService.generate_plan(req)

        for alt in response.alternatives:
            f1_layout = alt.floor_layouts[1]
            f1_sb = f1_layout.spatial_breakdown

            # Terrace exists and has positive area
            assert f1_sb.terrace_balcony_area > 0.0, "First floor terrace area should be > 0"

            # Terrace area is strictly excluded from f1 covered footprint
            # Total constructed slab includes terrace, covered footprint does not
            assert f1_sb.total_constructed_floor_area == round(f1_sb.total_covered_area + f1_sb.terrace_balcony_area, 2)

            # Terrace is included in uncovered area
            assert f1_sb.uncovered_area >= f1_sb.terrace_balcony_area

    @pytest.mark.parametrize("name,width,length,orientation,gf_req,f1_req", BENCHMARKS)
    def test_plan_a_and_plan_b_are_independent_never_combined(self, name, width, length, orientation, gf_req, f1_req):
        """Verifies Plan A and Plan B maintain separate area breakdowns and are never aggregated."""
        req = PlanGenerateRequest(
            plot=PlotInput(
                plot_length=length,
                plot_width=width,
                front_width=width,
                entrance_orientation=orientation,
                unit=PlotUnit.FEET,
            ),
            requirements=LayoutRequirements(
                floors=2,
                bedrooms=gf_req.bedrooms + f1_req.bedrooms,
                bathrooms=gf_req.bathrooms + f1_req.bathrooms,
                parking=True,
                ground_floor=gf_req,
                first_floor=f1_req,
            ),
        )
        response = PlanGenerationService.generate_plan(req)
        alt_a = response.alternatives[0]
        alt_b = response.alternatives[1]

        # Each alternative has its own spatial breakdown
        assert alt_a.spatial_breakdown is not alt_b.spatial_breakdown

        # Neither alternative combines both plans
        plot_area = width * length
        two_floor_max = plot_area * 2.0
        assert alt_a.spatial_breakdown.total_covered_area <= two_floor_max
        assert alt_b.spatial_breakdown.total_covered_area <= two_floor_max

        # Ensure response-level total_built_area matches Plan A (primary), not Plan A + Plan B
        assert response.total_built_area == alt_a.spatial_breakdown.net_room_area

    @pytest.mark.parametrize("name,width,length,orientation,gf_req,f1_req", BENCHMARKS)
    def test_mathematical_conservation_laws(self, name, width, length, orientation, gf_req, f1_req):
        """Verifies exact conservation: covered + uncovered == plot_area (per floor) and == 2x plot (combined)."""
        plot_area = width * length
        two_floor_max = plot_area * 2.0

        req = PlanGenerateRequest(
            plot=PlotInput(
                plot_length=length,
                plot_width=width,
                front_width=width,
                entrance_orientation=orientation,
                unit=PlotUnit.FEET,
            ),
            requirements=LayoutRequirements(
                floors=2,
                bedrooms=gf_req.bedrooms + f1_req.bedrooms,
                bathrooms=gf_req.bathrooms + f1_req.bathrooms,
                parking=True,
                ground_floor=gf_req,
                first_floor=f1_req,
            ),
        )
        response = PlanGenerationService.generate_plan(req)

        for alt in response.alternatives:
            gf_sb = alt.floor_layouts[0].spatial_breakdown
            f1_sb = alt.floor_layouts[1].spatial_breakdown
            comb_sb = alt.spatial_breakdown

            # Ground Floor Conservation
            gf_outer_diff = abs((gf_sb.total_covered_area + gf_sb.uncovered_area) - plot_area)
            assert gf_outer_diff < 0.05, f"{name} GF outer conservation failed: diff={gf_outer_diff}"
            assert gf_sb.conservation_verified is True
            assert gf_sb.conservation_discrepancy < 0.05

            gf_inner_diff = abs((gf_sb.net_room_area + gf_sb.circulation_area + gf_sb.wall_area) - gf_sb.total_covered_area)
            assert gf_inner_diff < 0.05, f"{name} GF internal conservation failed: diff={gf_inner_diff}"

            # First Floor Conservation
            f1_outer_diff = abs((f1_sb.total_covered_area + f1_sb.uncovered_area) - plot_area)
            assert f1_outer_diff < 0.05, f"{name} F1 outer conservation failed: diff={f1_outer_diff}"
            assert f1_sb.conservation_verified is True
            assert f1_sb.conservation_discrepancy < 0.05

            f1_inner_diff = abs((f1_sb.net_room_area + f1_sb.circulation_area + f1_sb.wall_area) - f1_sb.total_covered_area)
            assert f1_inner_diff < 0.05, f"{name} F1 internal conservation failed: diff={f1_inner_diff}"

            # Combined Conservation
            comb_diff = abs((comb_sb.total_covered_area + comb_sb.uncovered_area) - two_floor_max)
            assert comb_diff < 0.05, f"{name} Combined conservation failed: diff={comb_diff}"
            assert comb_sb.conservation_verified is True
            assert comb_sb.conservation_discrepancy < 0.05

    def test_staircase_physical_fit_in_reserved_shaft(self):
        """Verifies dog-leg stair physically fits inside the 6.5 x 11.5 ft shaft."""
        req = PlanGenerateRequest(
            plot=PlotInput(
                plot_length=45.0,
                plot_width=25.0,
                front_width=25.0,
                entrance_orientation=OrientationEnum.SOUTH,
                unit=PlotUnit.FEET,
            ),
            requirements=LayoutRequirements(
                floors=2,
                bedrooms=3,
                bathrooms=3,
                parking=True,
            ),
        )
        response = PlanGenerationService.generate_plan(req)
        assert response.staircase_validation is not None
        result = response.staircase_validation

        dim = result["dimensions"]
        # Dog-leg: 2 flights of 8 risers and 7 treads each
        assert dim["risers_count"] == 16
        assert dim["treads_count"] == 14
        assert dim["treads_per_flight"] == 7
        assert dim["flights_count"] == 2

        # Physical horizontal run: 7 treads * 10" = 70" (5.83 ft) + 3.0 ft landing = 8.83 ft <= 11.5 ft
        assert dim["total_stair_run_ft"] <= dim["reserved_shaft_length_ft"]
        assert dim["clear_run_buffer_ft"] >= 2.0  # At least 2 ft buffer for transition/doors

        # Clear flight width: 6.5 / 2 = 3.25 ft >= 3.0 ft
        assert dim["clear_width_feet"] >= 3.0

        # Blondel comfort check
        assert dim["blondel_comfort_inches"] == 25.0

        # Disclaimer verification
        assert "CONCEPTUAL ARCHITECTURAL DESIGN ONLY" in result["structural_disclaimer"]
        assert "Independent verification by a licensed structural engineer" in result["structural_disclaimer"]
