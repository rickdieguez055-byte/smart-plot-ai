import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smartplot_ai_module/models/floor_plan_result.dart';
import 'package:smartplot_ai_module/providers/plan_provider.dart';
import 'package:smartplot_ai_module/screens/edit_floor_plan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleGfRooms = [
    const RoomModel(id: 'porch_gf', name: 'Car Porch & Parking', category: 'parking', x: 0.0, y: 0.0, width: 11.5, length: 14.4, area: 165.6, floor: 1),
    const RoomModel(id: 'stair_gf', name: 'Staircase Core', category: 'staircase', x: 0.0, y: 14.4, width: 6.5, length: 11.5, area: 74.75, floor: 1),
    const RoomModel(id: 'drawing_gf', name: 'Drawing Room', category: 'drawing', x: 11.5, y: 0.0, width: 13.5, length: 14.4, area: 194.4, floor: 1),
    const RoomModel(id: 'living_gf', name: 'Living Room', category: 'living', x: 6.5, y: 14.4, width: 18.5, length: 15.6, area: 288.6, floor: 1),
    const RoomModel(id: 'kitchen_gf', name: 'Kitchen', category: 'kitchen', x: 0.0, y: 25.9, width: 6.5, length: 9.1, area: 59.15, floor: 1),
    const RoomModel(id: 'bed_gf', name: 'Master Bedroom', category: 'bedroom', x: 0.0, y: 35.0, width: 13.5, length: 10.0, area: 135.0, floor: 1),
    const RoomModel(id: 'bath_gf', name: 'Attached Bath', category: 'bathroom', x: 13.5, y: 35.0, width: 11.5, length: 10.0, area: 115.0, floor: 1),
  ];

  final sampleF1Rooms = [
    const RoomModel(id: 'terrace_f1', name: 'Front Open Terrace', category: 'terrace', x: 0.0, y: 0.0, width: 11.5, length: 11.7, area: 134.55, floor: 2),
    const RoomModel(id: 'stair_f1', name: 'Staircase Core', category: 'staircase', x: 0.0, y: 14.4, width: 6.5, length: 11.5, area: 74.75, floor: 2),
    const RoomModel(id: 'lounge_f1', name: 'Upper Family Lounge', category: 'living', x: 6.5, y: 14.4, width: 18.5, length: 15.6, area: 288.6, floor: 2),
    const RoomModel(id: 'bed1_f1', name: 'Family Bedroom 1', category: 'bedroom', x: 0.0, y: 25.9, width: 12.5, length: 9.1, area: 113.75, floor: 2),
    const RoomModel(id: 'bath1_f1', name: 'Attached Bath 1', category: 'bathroom', x: 12.5, y: 25.9, width: 12.5, length: 9.1, area: 113.75, floor: 2),
    const RoomModel(id: 'bed2_f1', name: 'Family Bedroom 2', category: 'bedroom', x: 0.0, y: 35.0, width: 13.5, length: 10.0, area: 135.0, floor: 2),
    const RoomModel(id: 'bath2_f1', name: 'Attached Bath 2', category: 'bathroom', x: 13.5, y: 35.0, width: 11.5, length: 10.0, area: 115.0, floor: 2),
  ];

  const sampleBreakdown = SpatialBreakdownModel(
    totalPlotArea: 1125.0,
    netRoomArea: 1413.2,
    circulationArea: 382.9,
    wallArea: 234.8,
    openUnallocatedArea: 219.0,
    setbackArea: 0.0,
    totalCoveredArea: 2031.0,
    utilizationPercentage: 90.3,
    groundCoveredFootprint: 1125.0,
    firstCoveredFootprint: 906.0,
    roomUsableArea: 1413.2,
    staircaseArea: 74.75,
    terraceBalconyArea: 134.55,
    totalConstructedFloorArea: 2165.55,
    uncoveredArea: 219.0,
    conservationVerified: true,
    conservationDiscrepancy: 0.0,
  );

  final sampleGfLayout = FloorLayoutModel(
    floor: 1,
    name: 'Ground Floor Plan',
    rooms: sampleGfRooms,
    circulationPaths: const [
      CirculationPathModel(id: 'foyer', name: 'Main Foyer', x: 6.5, y: 0.0, width: 5.0, length: 8.0, area: 40.0),
    ],
    doors: const [
      DoorModel(id: 'd1', fromRoom: 'exterior', toRoom: 'foyer', x: 9.0, y: 0.0, width: 3.5, wall: 'south'),
    ],
    windows: const [
      WindowModel(id: 'w1', room: 'drawing_gf', x: 18.0, y: 0.0, width: 4.0, wall: 'south'),
    ],
    spatialBreakdown: sampleBreakdown,
    svgFloorPlan: '<svg width="800" height="1200"><rect width="800" height="1200" fill="white"/></svg>',
  );

  final sampleF1Layout = FloorLayoutModel(
    floor: 2,
    name: 'First Floor Plan',
    rooms: sampleF1Rooms,
    circulationPaths: const [
      CirculationPathModel(id: 'upper_landing', name: 'Arrival Landing', x: 0.0, y: 14.4, width: 6.5, length: 4.0, area: 26.0),
    ],
    doors: const [],
    windows: const [],
    spatialBreakdown: sampleBreakdown,
    svgFloorPlan: '<svg width="800" height="1200"><rect width="800" height="1200" fill="white"/></svg>',
  );

  final sampleAlternativeA = PlanAlternativeModel(
    layoutType: 'open_living',
    title: 'Plan A: Multi-Floor Modern Open Concept',
    description: 'Two-story contemporary residence',
    rooms: [...sampleGfRooms, ...sampleF1Rooms],
    circulationPaths: sampleGfLayout.circulationPaths,
    doors: sampleGfLayout.doors,
    windows: sampleGfLayout.windows,
    spatialBreakdown: sampleBreakdown,
    recommendations: const [],
    svgFloorPlan: sampleGfLayout.svgFloorPlan,
    floorsCount: 2,
    floorLayouts: [sampleGfLayout, sampleF1Layout],
    svgGroundFloor: sampleGfLayout.svgFloorPlan,
    svgFirstFloor: sampleF1Layout.svgFloorPlan,
    staircaseAligned: true,
  );

  final sampleResult = FloorPlanResult(
    planId: 'plan_phase7_test_001',
    rooms: sampleGfRooms,
    totalBuiltArea: 1413.2,
    circulationArea: 382.9,
    utilizationPercentage: 90.3,
    spatialBreakdown: sampleBreakdown,
    svgFloorPlan: sampleGfLayout.svgFloorPlan,
    recommendations: const [],
    disclaimer: 'Conceptual design',
    alternatives: [sampleAlternativeA],
    floorsCount: 2,
    floorLayouts: [sampleGfLayout, sampleF1Layout],
  );

  group('Phase 7: Editable Geometry Model Unit Tests', () {
    test('RoomModel serialization and copyWith', () {
      final room = sampleGfRooms.first;
      final json = room.toJson();
      expect(json['id'], 'porch_gf');
      expect(json['width'], 11.5);
      expect(json['length'], 14.4);

      final modified = room.copyWith(width: 12.0, x: 1.0);
      expect(modified.width, 12.0);
      expect(modified.x, 1.0);
      expect(modified.area, 12.0 * 14.4);
      expect(modified.id, 'porch_gf');
    });

    test('FloorLayoutModel serialization and copyWith', () {
      final json = sampleGfLayout.toJson();
      expect(json['floor'], 1);
      expect(json['rooms'], isA<List>());
      expect((json['rooms'] as List).length, 7);

      final modified = sampleGfLayout.copyWith(name: 'Updated Ground Floor');
      expect(modified.name, 'Updated Ground Floor');
      expect(modified.rooms.length, 7);
    });

    test('PlanAlternativeModel copyWith preserves multi-floor layouts', () {
      final modified = sampleAlternativeA.copyWith(title: 'Custom Plan A');
      expect(modified.title, 'Custom Plan A');
      expect(modified.floorLayouts.length, 2);
      expect(modified.floorsCount, 2);
    });
  });

  group('Phase 7: PlanProvider Interactive Editing State Tests', () {
    test('initEditingSession initializes session and selections', () {
      final provider = PlanProvider();
      provider.setResultForTesting(sampleResult);

      provider.initEditingSession(sampleAlternativeA);
      expect(provider.activeEditingAlternative, isNotNull);
      expect(provider.originalGeneratedAlternative, isNotNull);
      expect(provider.selectedRoomId, 'porch_gf');
      expect(provider.canUndo, isFalse);
      expect(provider.canRedo, isFalse);
    });

    test('updateRoomGeometry pushes to undo stack and updates coordinates', () {
      final provider = PlanProvider();
      provider.setResultForTesting(sampleResult);
      provider.initEditingSession(sampleAlternativeA);

      // Modify master bed width
      provider.updateRoomGeometry('bed_gf', width: 14.0, floor: 1);
      expect(provider.canUndo, isTrue);
      expect(provider.canRedo, isFalse);

      final bed = provider.activeEditingAlternative!.rooms.firstWhere((r) => r.id == 'bed_gf');
      expect(bed.width, 14.0);

      // Undo
      provider.undo();
      expect(provider.canUndo, isFalse);
      expect(provider.canRedo, isTrue);
      final revertedBed = provider.activeEditingAlternative!.rooms.firstWhere((r) => r.id == 'bed_gf');
      expect(revertedBed.width, 13.5);

      // Redo
      provider.redo();
      expect(provider.canUndo, isTrue);
      expect(provider.canRedo, isFalse);
      final redoneBed = provider.activeEditingAlternative!.rooms.firstWhere((r) => r.id == 'bed_gf');
      expect(redoneBed.width, 14.0);
    });

    test('resetToOriginal restores AI generated layout', () {
      final provider = PlanProvider();
      provider.setResultForTesting(sampleResult);
      provider.initEditingSession(sampleAlternativeA);

      provider.updateRoomGeometry('bed_gf', width: 16.0, x: 2.0, floor: 1);
      final modifiedBed = provider.activeEditingAlternative!.rooms.firstWhere((r) => r.id == 'bed_gf');
      expect(modifiedBed.width, 16.0);

      provider.resetToOriginal();
      final resetBed = provider.activeEditingAlternative!.rooms.firstWhere((r) => r.id == 'bed_gf');
      expect(resetBed.width, 13.5);
      expect(resetBed.x, 0.0);
    });

    test('selectRoom updates selected room ID', () {
      final provider = PlanProvider();
      provider.setResultForTesting(sampleResult);
      provider.initEditingSession(sampleAlternativeA);

      provider.selectRoom('drawing_gf');
      expect(provider.selectedRoomId, 'drawing_gf');
    });
  });

  group('Phase 7: EditFloorPlanScreen Widget Tests', () {
    testWidgets('Renders Interactive Editor with Canvas, Toolbar, and Controls', (tester) async {
      final provider = PlanProvider();
      provider.setResultForTesting(sampleResult);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlanProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: EditFloorPlanScreen(initialFloor: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Interactive Floor Plan Editor'), findsOneWidget);

      // Verify Actions in AppBar (Undo, Redo, Reset, Save)
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
      expect(find.byTooltip('Reset to Original AI Plan'), findsOneWidget);
      expect(find.byTooltip('Save Custom Plan'), findsOneWidget);

      // Verify Floor choice chips
      expect(find.text('GF'), findsOneWidget);
      expect(find.text('1F'), findsOneWidget);

      // Verify Dimension Controls
      expect(find.text('Width'), findsOneWidget);
      expect(find.text('Length'), findsOneWidget);
      expect(find.text('X Position'), findsOneWidget);
      expect(find.text('Y Position'), findsOneWidget);

      // Verify Apply & Recalculate Button
      expect(find.text('Apply & Recalculate Layout'), findsOneWidget);
    });

    testWidgets('Tapping 1F switches floor and shows First Floor rooms', (tester) async {
      final provider = PlanProvider();
      provider.setResultForTesting(sampleResult);

      await tester.pumpWidget(
        ChangeNotifierProvider<PlanProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: EditFloorPlanScreen(initialFloor: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 1F chip
      await tester.tap(find.text('1F'));
      await tester.pumpAndSettle();

      // Selected room should now be from First Floor
      expect(provider.selectedRoomId, startsWith('terrace_f1'));
    });
  });
}
