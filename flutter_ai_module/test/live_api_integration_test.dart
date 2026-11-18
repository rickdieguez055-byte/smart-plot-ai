import 'package:flutter_test/flutter_test.dart';
import 'package:smartplot_ai_module/models/plot_input.dart';
import 'package:smartplot_ai_module/services/ai_plan_api_service.dart';

void main() {
  test('Live Gateway Integration Test (25x45 ft plot)', () async {
    final apiService = AiPlanApiService(initialBaseUrl: 'http://127.0.0.1:5000');

    // 1. Check Gateway Connectivity
    final isHealthy = await apiService.checkHealth();
    if (!isHealthy) {
      // Allow unit test suite to pass in offline CI environments (e.g. Codemagic)
      print('[SKIP] Node.js Gateway not running at http://127.0.0.1:5000. Skipping live integration test.');
      return;
    }

    // 2. Request Floor Plan for Standard 25x45 ft plot
    const input = PlotInput(
      plotLength: 45.0,
      plotWidth: 25.0,
      frontWidth: 25.0,
      entranceOrientation: 'South',
      unit: 'feet',
      bedrooms: 2,
      bathrooms: 2,
      kitchen: true,
      livingRoom: true,
      parking: true,
    );

    final result = await apiService.generatePlan(input);

    // 3. Verify Real API Response
    expect(result.planId, isNotEmpty);
    expect(result.planId.startsWith('plan_'), isTrue);
    expect(result.totalBuiltArea, greaterThan(0));
    expect(result.circulationArea, greaterThan(0));
    expect(result.utilizationPercentage, greaterThan(0));
    expect(result.disclaimer.toLowerCase(), contains('preliminary'));

    // 4. Verify Dual Plan Alternatives
    expect(result.alternatives.length, 2, reason: 'Backend must return both Plan A and Plan B');

    final planA = result.alternatives[0];
    expect(planA.layoutType, 'open_living');
    expect(planA.title, contains('Plan A'));
    expect(planA.isFeasible, isTrue);
    expect(planA.connectivityVerified, isTrue);
    expect(planA.rooms.length, greaterThanOrEqualTo(5));
    expect(planA.doors.length, greaterThanOrEqualTo(6));
    expect(planA.windows.length, greaterThanOrEqualTo(6));
    expect(planA.svgFloorPlan, contains('<svg'));
    expect(planA.svgFloorPlan, contains('SP-AI-10'));

    final planB = result.alternatives[1];
    expect(planB.layoutType, 'privacy_focused');
    expect(planB.title, contains('Plan B'));
    expect(planB.isFeasible, isTrue);
    expect(planB.connectivityVerified, isTrue);
    expect(planB.rooms.length, greaterThanOrEqualTo(5));
    expect(planB.doors.length, greaterThanOrEqualTo(6));
    expect(planB.windows.length, greaterThanOrEqualTo(6));
    expect(planB.svgFloorPlan, contains('<svg'));
    expect(planB.svgFloorPlan, contains('Formal Drawing Room'));

    print('Live API Test Successful:');
    print('  Plan ID: ${result.planId}');
    print('  Plan A: ${planA.title} (Rooms: ${planA.rooms.length}, Doors: ${planA.doors.length}, Windows: ${planA.windows.length})');
    print('  Plan B: ${planB.title} (Rooms: ${planB.rooms.length}, Doors: ${planB.doors.length}, Windows: ${planB.windows.length})');
  });
}
