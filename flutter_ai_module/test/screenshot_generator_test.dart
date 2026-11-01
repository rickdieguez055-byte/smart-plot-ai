import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartplot_ai_module/config/theme.dart';
import 'package:smartplot_ai_module/models/floor_plan_result.dart';
import 'package:smartplot_ai_module/models/plot_input.dart';
import 'package:smartplot_ai_module/providers/plan_provider.dart';
import 'package:smartplot_ai_module/screens/ai_planning_home_screen.dart';
import 'package:smartplot_ai_module/screens/plot_form_screen.dart';
import 'package:smartplot_ai_module/screens/requirements_form_screen.dart';
import 'package:smartplot_ai_module/screens/plan_results_screen.dart';
import 'package:smartplot_ai_module/screens/plan_comparison_screen.dart';
import 'package:smartplot_ai_module/screens/detailed_plan_viewer_screen.dart';
import 'package:smartplot_ai_module/services/ai_plan_api_service.dart';

class MockPreloadedProvider extends PlanProvider {
  MockPreloadedProvider(FloorPlanResult result) {
    // Set preloaded result directly
    updateBaseUrl('http://127.0.0.1:5000');
    // Call private field setter via custom test method or helper
    setTestResult(result);
  }

  void setTestResult(FloorPlanResult result) {
    // We can expose a test setter or set in provider
    setResultForTesting(result);
  }
}

void main() {
  testWidgets('Capture Screenshots for Phase 3 Verification', (tester) async {
    HttpOverrides.global = null; // Restore default real HTTP client
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final screenshotsDir = Directory('D:/smart plot_ai/docs/screenshots');
    if (!screenshotsDir.existsSync()) {
      screenshotsDir.createSync(recursive: true);
    }

    // 1. Fetch real live floor plan from Gateway using runAsync
    late FloorPlanResult realResult;
    await tester.runAsync(() async {
      final api = AiPlanApiService(initialBaseUrl: 'http://127.0.0.1:5000');
      realResult = await api.generatePlan(const PlotInput(
        plotLength: 45.0,
        plotWidth: 25.0,
        frontWidth: 25.0,
        entranceOrientation: 'South',
        bedrooms: 2,
        bathrooms: 2,
        kitchen: true,
        livingRoom: true,
        parking: true,
      ));
    });

    expect(realResult, isNotNull);
    expect(realResult.alternatives.length, 2);

    final provider = PlanProvider(initialBaseUrl: 'http://127.0.0.1:5000');
    provider.setResultForTesting(realResult);

    Future<void> captureScreen(Widget screen, String filename) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlanProvider>.value(value: provider),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: SmartPlotTheme.lightTheme,
            home: RepaintBoundary(
              key: boundaryKey,
              child: screen,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final RenderRepaintBoundary boundary =
          boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      late List<int> pngBytes;
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData!.buffer.asUint8List();
      });

      final file = File('${screenshotsDir.path}/$filename');
      file.writeAsBytesSync(pngBytes);
      print('  ✓ Captured: $filename (${file.lengthSync()} bytes)');
    }

    print('Generating Phase 3 Verified Screen Captures:');
    // 1. Home Screen
    await captureScreen(const AiPlanningHomeScreen(), '1_ai_planning_home.png');

    // 2. Plot Form Screen
    await captureScreen(const PlotFormScreen(), '2_plot_measurements_form.png');

    // 3. Requirements Form Screen
    await captureScreen(const RequirementsFormScreen(), '3_room_requirements_form.png');

    // 4. Plan Results Screen (Plan A)
    provider.selectAlternative(0);
    await captureScreen(const PlanResultsScreen(), '4_plan_results_plan_a.png');

    // 5. Plan Results Screen (Plan B)
    provider.selectAlternative(1);
    await captureScreen(const PlanResultsScreen(), '5_plan_results_plan_b.png');

    // 6. Plan Comparison Screen
    await captureScreen(const PlanComparisonScreen(), '6_plan_a_vs_b_comparison.png');

    // 7. Detailed Viewer Screen
    await captureScreen(const DetailedPlanViewerScreen(), '7_detailed_plan_viewer.png');

    print('All screen captures saved successfully to docs/screenshots/');
  });
}
