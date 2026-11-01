import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/plan_provider.dart';
import 'screens/ai_planning_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPlotAiApp());
}

class SmartPlotAiApp extends StatelessWidget {
  const SmartPlotAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()),
      ],
      child: MaterialApp(
        title: 'SmartPlot AI',
        debugShowCheckedModeBanner: false,
        theme: SmartPlotTheme.lightTheme,
        home: const AiPlanningHomeScreen(),
      ),
    );
  }
}
