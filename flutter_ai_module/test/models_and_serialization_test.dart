import 'package:flutter_test/flutter_test.dart';
import 'package:smartplot_ai_module/models/plot_input.dart';
import 'package:smartplot_ai_module/models/floor_plan_result.dart';
import 'package:smartplot_ai_module/services/entitlement_service.dart';

void main() {
  group('PlotInput Model & Validation Tests', () {
    test('Standard 5 Marla input serializes correctly', () {
      const input = PlotInput(
        plotLength: 45.0,
        plotWidth: 25.0,
        frontWidth: 25.0,
        entranceOrientation: 'South',
        unit: 'feet',
        bedrooms: 2,
        bathrooms: 2,
      );

      final json = input.toJson();
      expect(json.containsKey('plot'), isTrue);
      expect(json.containsKey('requirements'), isTrue);

      final plot = json['plot'] as Map<String, dynamic>;
      expect(plot['plot_length'], 45.0);
      expect(plot['plot_width'], 25.0);
      expect(plot['front_width'], 25.0);
      expect(plot['entrance_orientation'], 'South');

      final req = json['requirements'] as Map<String, dynamic>;
      expect(req['bedrooms'], 2);
      expect(req['bathrooms'], 2);
      expect(req['kitchen'], isTrue);
      expect(req['living_room'], isTrue);
      expect(req['parking'], isTrue);
    });

    test('Validates negative and zero dimensions', () {
      const invalidLength = PlotInput(
        plotLength: -45.0,
        plotWidth: 25.0,
        frontWidth: 25.0,
        entranceOrientation: 'South',
      );
      expect(invalidLength.validate(), isNotNull);

      const invalidWidth = PlotInput(
        plotLength: 45.0,
        plotWidth: 0.0,
        frontWidth: 0.0,
        entranceOrientation: 'South',
      );
      expect(invalidWidth.validate(), isNotNull);
    });

    test('Validates front width exceeding plot width', () {
      const excessiveFront = PlotInput(
        plotLength: 45.0,
        plotWidth: 25.0,
        frontWidth: 30.0,
        entranceOrientation: 'South',
      );
      expect(excessiveFront.validate(), contains('Front width'));
    });

    test('Validates minimum residential dimensions', () {
      const tooSmall = PlotInput(
        plotLength: 10.0,
        plotWidth: 8.0,
        frontWidth: 8.0,
        entranceOrientation: 'North',
      );
      expect(tooSmall.validate(), contains('too small'));
    });
  });

  group('FloorPlanResult & Dual Alternatives Deserialization', () {
    test('Parses full backend response with Plan A and Plan B', () {
      final sampleResponse = {
        'plan_id': 'plan_test_123',
        'total_built_area': 1125.0,
        'circulation_area': 171.0,
        'utilization_percentage': 100.0,
        'svg_floor_plan': '<svg>Plan A Root</svg>',
        'disclaimer': '⚠️ MANDATORY PRELIMINARY NOTICE (SP-AI-10)',
        'rooms': [
          {
            'id': 'room_1',
            'name': 'Living Room',
            'category': 'living',
            'x': 0.0,
            'y': 6.0,
            'width': 13.5,
            'length': 14.0,
            'area': 189.0,
            'floor': 1,
          }
        ],
        'recommendations': [
          {
            'category': 'ventilation',
            'title': 'Cross Ventilation',
            'description': 'Verified exterior fenestration.',
            'score': 8.5,
          }
        ],
        'alternatives': [
          {
            'layout_type': 'open_living',
            'title': 'Plan A: Open Living Concept',
            'description': 'Features integrated living and dining with open flow.',
            'rooms': [
              {
                'id': 'room_1',
                'name': 'Living Room',
                'category': 'living',
                'x': 0.0,
                'y': 6.0,
                'width': 13.5,
                'length': 14.0,
                'area': 189.0,
                'floor': 1,
              }
            ],
            'circulation_paths': [
              {
                'id': 'foyer',
                'name': 'Entrance Foyer',
                'x': 0.0,
                'y': 0.0,
                'width': 13.5,
                'length': 6.0,
                'area': 81.0,
              }
            ],
            'doors': [
              {
                'id': 'door_1',
                'from_room': 'exterior',
                'to_room': 'foyer',
                'x': 6.75,
                'y': 0.0,
                'width': 3.5,
                'wall': 'south',
                'is_exterior': true,
              }
            ],
            'windows': [
              {
                'id': 'win_1',
                'room': 'room_1',
                'x': 0.0,
                'y': 10.0,
                'width': 5.0,
                'wall': 'west',
                'is_exterior': true,
              }
            ],
            'spatial_breakdown': {
              'total_plot_area': 1125.0,
              'net_room_area': 820.59,
              'circulation_area': 171.0,
              'wall_area': 133.41,
              'open_unallocated_area': 0.0,
              'setback_area': 0.0,
              'total_covered_area': 1125.0,
              'utilization_percentage': 100.0,
            },
            'recommendations': [],
            'svg_floor_plan': '<svg>Plan A</svg>',
            'is_feasible': true,
            'connectivity_verified': true,
          },
          {
            'layout_type': 'privacy_focused',
            'title': 'Plan B: Privacy Focused',
            'description': 'Features formal drawing room for guests.',
            'rooms': [],
            'circulation_paths': [],
            'doors': [],
            'windows': [],
            'spatial_breakdown': {
              'total_plot_area': 1125.0,
              'net_room_area': 836.84,
              'circulation_area': 152.3,
              'wall_area': 135.86,
              'open_unallocated_area': 0.0,
              'setback_area': 0.0,
              'total_covered_area': 1125.0,
              'utilization_percentage': 100.0,
            },
            'recommendations': [],
            'svg_floor_plan': '<svg>Plan B</svg>',
            'is_feasible': true,
            'connectivity_verified': true,
          }
        ],
      };

      final result = FloorPlanResult.fromJson(sampleResponse);
      expect(result.planId, 'plan_test_123');
      expect(result.alternatives.length, 2);

      final planA = result.alternatives[0];
      expect(planA.layoutType, 'open_living');
      expect(planA.title, contains('Plan A'));
      expect(planA.isFeasible, isTrue);
      expect(planA.doors.length, 1);
      expect(planA.doors.first.isExterior, isTrue);
      expect(planA.windows.length, 1);
      expect(planA.spatialBreakdown.totalCoveredArea, 1125.0);

      final planB = result.alternatives[1];
      expect(planB.layoutType, 'privacy_focused');
      expect(planB.title, contains('Plan B'));
    });
  });

  group('Entitlement Service Tests (Task 5)', () {
    test('Initializes with 2 free generations', () {
      final service = EntitlementService();
      expect(service.maxFreeQuota, 2);
      expect(service.usedGenerations, 0);
      expect(service.remainingFreeGenerations, 2);
      expect(service.canGenerateFree, isTrue);
    });

    test('Records generations and locks tier', () {
      final service = EntitlementService();
      service.recordGeneration();
      expect(service.usedGenerations, 1);
      expect(service.remainingFreeGenerations, 1);
      expect(service.canGenerateFree, isTrue);

      service.recordGeneration();
      expect(service.usedGenerations, 2);
      expect(service.remainingFreeGenerations, 0);
      expect(service.canGenerateFree, isFalse);

      // Reset for evaluation
      service.resetPrototypeTier();
      expect(service.remainingFreeGenerations, 2);
      expect(service.canGenerateFree, isTrue);
    });
  });
}
