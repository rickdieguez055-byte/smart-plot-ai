library loading_generation_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import 'plan_results_screen.dart';

class LoadingGenerationScreen extends StatefulWidget {
  const LoadingGenerationScreen({super.key});

  @override
  State<LoadingGenerationScreen> createState() => _LoadingGenerationScreenState();
}

class _LoadingGenerationScreenState extends State<LoadingGenerationScreen> {
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      _executeGeneration();
    }
  }

  Future<void> _executeGeneration() async {
    final provider = context.read<PlanProvider>();
    final success = await provider.generateFloorPlan();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PlanResultsScreen()),
      );
    } else {
      _showErrorDialog(provider.errorMessage ?? 'An unknown error occurred.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: SmartPlotTheme.errorRed, size: 24),
            SizedBox(width: 8),
            Text('Generation Failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: SmartPlotTheme.navyText, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            child: const Text('Edit Inputs'),
            onPressed: () {
              Navigator.pop(ctx); // pop dialog
              Navigator.pop(context); // pop back to requirements
            },
          ),
          ElevatedButton(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.pop(ctx);
              _executeGeneration();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    return PopScope(
      canPop: false, // Prevent accidental dismissal during generation
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: SmartPlotTheme.emeraldSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(SmartPlotTheme.primaryEmerald),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Generating AI Floor Plans',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: SmartPlotTheme.navyDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.loadingStep,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SmartPlotTheme.slateMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SmartPlotTheme.bgPure,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SmartPlotTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem('1. Spatial dimensional feasibility', true),
                        const SizedBox(height: 8),
                        _buildStepItem('2. Google OR-Tools constraint satisfaction', true),
                        const SizedBox(height: 8),
                        _buildStepItem('3. Dual architectural layouts (Open vs. Privacy)', true),
                        const SizedBox(height: 8),
                        _buildStepItem('4. Door cutouts, swing arcs & exterior windows', true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String title, bool active) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: SmartPlotTheme.primaryEmerald),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SmartPlotTheme.navyDark,
            ),
          ),
        ),
      ],
    );
  }
}
