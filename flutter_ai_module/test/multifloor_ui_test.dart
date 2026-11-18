import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartplot_ai_module/config/theme.dart';
import 'package:smartplot_ai_module/models/floor_plan_result.dart';
import 'package:smartplot_ai_module/models/plot_input.dart';
import 'package:smartplot_ai_module/providers/plan_provider.dart';
import 'package:smartplot_ai_module/screens/detailed_plan_viewer_screen.dart';
import 'package:smartplot_ai_module/screens/plan_results_screen.dart';
import 'package:smartplot_ai_module/screens/requirements_form_screen.dart';

Widget createTestableWidget(Widget child, {PlanProvider? provider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PlanProvider>(
        create: (_) => provider ?? PlanProvider(),
      ),
    ],
    child: MaterialApp(
      theme: SmartPlotTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('SmartPlot AI Phase 6 Multi-Floor UI & Model Tests', () {
    testWidgets('Requirements Form Screen allows selecting 2 Floors (G+1)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = PlanProvider();
      await tester.pumpWidget(createTestableWidget(const RequirementsFormScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Number of Floors'), findsOneWidget);
      expect(find.text('1 Floor (Ground)'), findsOneWidget);
      expect(find.text('2 Floors (G+1)'), findsOneWidget);

      // Tap 2 Floors
      await tester.tap(find.text('2 Floors (G+1)'));
      await tester.pumpAndSettle();

      expect(find.text('2 Floors (G+1)'), findsWidgets);
      expect(find.textContaining('100% vertical staircase alignment'), findsOneWidget);
    });

    testWidgets('Plan Results Screen renders Ground/First floor selector for multi-floor plan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = PlanProvider();

      const sampleSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><rect width="100" height="100" fill="#fff"/></svg>';
      const multifloorResult = FloorPlanResult(
        planId: 'plan_test_multi',
        totalBuiltArea: 1650.0,
        circulationArea: 180.0,
        utilizationPercentage: 75.0,
        svgFloorPlan: sampleSvg,
        svgGroundFloor: sampleSvg,
        svgFirstFloor: sampleSvg,
        floorsCount: 2,
        disclaimer: 'Preliminary Design Notice',
        rooms: [
          RoomModel(id: 'r1', name: 'Master Bed GF', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 1),
          RoomModel(id: 'r2', name: 'Bedroom 2 F1', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 2),
        ],
        recommendations: [],
        alternatives: [
          PlanAlternativeModel(
            layoutType: 'open_living',
            title: 'Plan A: Multi-Floor Modern Open Concept',
            description: 'Two-story contemporary residence',
            rooms: [
              RoomModel(id: 'r1', name: 'Master Bed GF', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 1),
              RoomModel(id: 'r2', name: 'Bedroom 2 F1', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 2),
            ],
            circulationPaths: [],
            doors: [],
            windows: [],
            spatialBreakdown: SpatialBreakdownModel(
              totalPlotArea: 1125.0,
              netRoomArea: 1650.0,
              circulationArea: 180.0,
              wallArea: 200.0,
              openUnallocatedArea: 100.0,
              setbackArea: 0.0,
              totalCoveredArea: 2030.0,
              utilizationPercentage: 90.0,
            ),
            recommendations: [],
            svgFloorPlan: sampleSvg,
            svgGroundFloor: sampleSvg,
            svgFirstFloor: sampleSvg,
            floorsCount: 2,
            staircaseAligned: true,
          ),
        ],
      );

      provider.setResultForTesting(multifloorResult);

      await tester.pumpWidget(createTestableWidget(const PlanResultsScreen(), provider: provider));
      await tester.pumpAndSettle();

      // Check for multi-floor segmented controls
      expect(find.text('Ground Floor (GF)'), findsOneWidget);
      expect(find.text('First Floor (1F)'), findsOneWidget);
      expect(find.textContaining('3D Vertical Staircase Core: 100% Coordinated Stack'), findsOneWidget);

      // Tap First Floor
      await tester.tap(find.text('First Floor (1F)'));
      await tester.pumpAndSettle();

      expect(find.text('First Floor (1F)'), findsOneWidget);
    });

    testWidgets('Detailed Plan Viewer Screen renders floor switcher for multi-floor plan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final provider = PlanProvider();
      const sampleSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><rect width="100" height="100" fill="#fff"/></svg>';
      const multifloorResult = FloorPlanResult(
        planId: 'plan_test_multi',
        totalBuiltArea: 1650.0,
        circulationArea: 180.0,
        utilizationPercentage: 75.0,
        svgFloorPlan: sampleSvg,
        svgGroundFloor: sampleSvg,
        svgFirstFloor: sampleSvg,
        floorsCount: 2,
        disclaimer: 'Preliminary Design Notice',
        rooms: [
          RoomModel(id: 'r1', name: 'Master Bed GF', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 1),
          RoomModel(id: 'r2', name: 'Bedroom 2 F1', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 2),
        ],
        recommendations: [],
        alternatives: [
          PlanAlternativeModel(
            layoutType: 'open_living',
            title: 'Plan A: Multi-Floor Modern Open Concept',
            description: 'Two-story contemporary residence',
            rooms: [
              RoomModel(id: 'r1', name: 'Master Bed GF', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 1),
              RoomModel(id: 'r2', name: 'Bedroom 2 F1', category: 'bedroom', x: 0, y: 0, width: 12, length: 14, area: 168, floor: 2),
            ],
            circulationPaths: [],
            doors: [],
            windows: [],
            spatialBreakdown: SpatialBreakdownModel(
              totalPlotArea: 1125.0,
              netRoomArea: 1650.0,
              circulationArea: 180.0,
              wallArea: 200.0,
              openUnallocatedArea: 100.0,
              setbackArea: 0.0,
              totalCoveredArea: 2030.0,
              utilizationPercentage: 90.0,
            ),
            recommendations: [],
            svgFloorPlan: sampleSvg,
            svgGroundFloor: sampleSvg,
            svgFirstFloor: sampleSvg,
            floorsCount: 2,
            staircaseAligned: true,
          ),
        ],
      );

      provider.setResultForTesting(multifloorResult);

      await tester.pumpWidget(createTestableWidget(const DetailedPlanViewerScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Ground Floor (GF)'), findsOneWidget);
      expect(find.text('First Floor (1F)'), findsOneWidget);
      expect(find.text('3D Staircase Aligned'), findsOneWidget);

      // Switch to First Floor
      await tester.tap(find.text('First Floor (1F)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('First Floor'), findsWidgets);
    });

    test('PlotInput correctly serializes and validates independent floor requirements', () {
      const gf = FloorRequirementModel(
        bedrooms: 1,
        bathrooms: 1,
        kitchen: true,
        livingRoom: true,
        drawingRoom: true,
      );
      const ff = FloorRequirementModel(
        bedrooms: 2,
        bathrooms: 2,
        kitchen: false,
        livingRoom: true,
        terrace: true,
      );
      const input = PlotInput(
        plotLength: 45,
        plotWidth: 25,
        frontWidth: 25,
        entranceOrientation: 'South',
        floors: 2,
        bedrooms: 3,
        bathrooms: 3,
        groundFloor: gf,
        firstFloor: ff,
      );

      expect(input.validate(), isNull);
      final json = input.toJson();
      expect(json['requirements']['floors'], equals(2));
      expect(json['requirements']['ground_floor'], isNotNull);
      expect(json['requirements']['ground_floor']['bedrooms'], equals(1));
      expect(json['requirements']['ground_floor']['drawing_room'], isTrue);
      expect(json['requirements']['first_floor'], isNotNull);
      expect(json['requirements']['first_floor']['bedrooms'], equals(2));
      expect(json['requirements']['first_floor']['terrace'], isTrue);
    });

    test('StaircaseValidationModel parses geometric metrics and Blondel formula', () {
      final json = {
        'is_valid': true,
        'aligned': true,
        'dx_alignment': 0.0,
        'dy_alignment': 0.0,
        'dimensions': {
          'riser_height_inches': 7.5,
          'tread_depth_inches': 10.0,
          'risers_count': 16,
          'treads_count': 15,
          'landing_depth_feet': 3.5,
          'clear_width_feet': 3.0,
          'headroom_clearance_feet': 6.67,
          'blondel_comfort_inches': 25.0,
        },
        'blondel_comfort_formula': '2R + T = 25.0 in',
        'headroom_cleared': true,
        'overlap_detected': false,
        'connectivity_verified': true,
        'ground_floor_indicator': 'UP ↑',
        'first_floor_indicator': 'DN ↓',
        'structural_disclaimer': 'NON-STRUCTURAL PRELIMINARY ARCHITECTURAL LAYOUT',
      };

      final model = StaircaseValidationModel.fromJson(json);
      expect(model.isValid, isTrue);
      expect(model.aligned, isTrue);
      expect(model.dxAlignment, equals(0.0));
      expect(model.dimensions['riser_height_inches'], equals(7.5));
      expect(model.dimensions['tread_depth_inches'], equals(10.0));
      expect(model.blondelComfortFormula, contains('25.0'));
      expect(model.groundFloorIndicator, equals('UP ↑'));
      expect(model.firstFloorIndicator, equals('DN ↓'));
    });
  });
}
