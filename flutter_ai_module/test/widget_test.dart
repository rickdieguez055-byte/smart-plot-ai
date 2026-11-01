import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartplot_ai_module/config/theme.dart';
import 'package:smartplot_ai_module/providers/plan_provider.dart';
import 'package:smartplot_ai_module/screens/ai_planning_home_screen.dart';
import 'package:smartplot_ai_module/screens/plot_form_screen.dart';
import 'package:smartplot_ai_module/screens/requirements_form_screen.dart';
import 'package:smartplot_ai_module/screens/settings_screen.dart';

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
  group('SmartPlot AI Widget & Navigation Tests', () {
    testWidgets('Home Screen displays branding, entitlement, and primary CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const AiPlanningHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SmartPlot AI'), findsOneWidget);
      expect(find.textContaining('Architectural Floor Plan'), findsOneWidget);
      expect(find.text('Free AI Generations'), findsOneWidget);
      expect(find.text('2 / 2 Available'), findsOneWidget);
      expect(find.text('Start New Floor Plan'), findsOneWidget);
    });

    testWidgets('Plot Form Screen renders fields and applies standard presets', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const PlotFormScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Plot Measurements'), findsOneWidget);
      expect(find.text('Feet (ft)'), findsOneWidget);
      expect(find.text('Meters (m)'), findsOneWidget);

      // Verify presets exist
      expect(find.text('5 Marla (25×45)'), findsOneWidget);
      expect(find.text('10 Marla (35×65)'), findsOneWidget);

      // Tap 10 Marla preset
      await tester.tap(find.text('10 Marla (35×65)'));
      await tester.pumpAndSettle();

      // Next button exists
      expect(find.text('Next: Room Requirements'), findsOneWidget);
    });

    testWidgets('Requirements Form Screen allows adjusting bedrooms and amenities', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const RequirementsFormScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Room Requirements'), findsOneWidget);
      expect(find.text('Bedrooms'), findsOneWidget);
      expect(find.text('Bathrooms'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Living Room / TV Lounge'), findsOneWidget);
      expect(find.text('Car Porch & Parking'), findsOneWidget);
      expect(find.text('Generate AI Floor Plans'), findsOneWidget);
    });

    testWidgets('Settings Screen enables gateway configuration and reset', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Gateway & App Settings'), findsOneWidget);
      expect(find.text('Gateway Base URL'), findsOneWidget);
      expect(find.text('Android Emulator (10.0.2.2:5000)'), findsOneWidget);
      expect(find.text('Save & Test Connection'), findsOneWidget);
      expect(find.text('Reset Free Generations for Testing'), findsOneWidget);
    });
  });
}
