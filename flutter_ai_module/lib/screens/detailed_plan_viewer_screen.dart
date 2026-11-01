library detailed_plan_viewer_screen;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/room_list_bottom_sheet.dart';

class DetailedPlanViewerScreen extends StatefulWidget {
  const DetailedPlanViewerScreen({super.key});

  @override
  State<DetailedPlanViewerScreen> createState() => _DetailedPlanViewerScreenState();
}

class _DetailedPlanViewerScreenState extends State<DetailedPlanViewerScreen> {
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _transformController.value.clone();
    matrix.scale(1.25, 1.25, 1.0);
    _transformController.value = matrix;
    setState(() => _currentScale *= 1.25);
  }

  void _zoomOut() {
    final matrix = _transformController.value.clone();
    matrix.scale(0.8, 0.8, 1.0);
    _transformController.value = matrix;
    setState(() => _currentScale *= 0.8);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  Future<void> _exportPlan() async {
    final provider = context.read<PlanProvider>();
    final path = await provider.saveCurrentPlanLocally();
    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Floor plan SVG saved to:\n$path'),
          backgroundColor: SmartPlotTheme.primaryEmerald,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final activePlan = provider.selectedAlternative;

    if (activePlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detailed Plan Viewer')),
        body: const Center(child: Text('No plan selected.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          activePlan.title,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export SVG locally',
            onPressed: _exportPlan,
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Room Schedule',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => RoomListBottomSheet(
                  rooms: activePlan.rooms,
                  circulationPaths: activePlan.circulationPaths,
                  planTitle: activePlan.title,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Plan A / Plan B Toggle Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SmartPlotTheme.bgSurface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Plan A: Open Living'),
                      selected: provider.selectedAlternativeIndex == 0,
                      selectedColor: SmartPlotTheme.emeraldSubtle,
                      labelStyle: TextStyle(
                        color: provider.selectedAlternativeIndex == 0
                            ? SmartPlotTheme.primaryEmerald
                            : SmartPlotTheme.slateMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) {
                          provider.selectAlternative(0);
                          _resetZoom();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Plan B: Privacy Focused'),
                      selected: provider.selectedAlternativeIndex == 1,
                      selectedColor: const Color(0xFFEEF2FF),
                      labelStyle: TextStyle(
                        color: provider.selectedAlternativeIndex == 1
                            ? const Color(0xFF4F46E5)
                            : SmartPlotTheme.slateMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) {
                          provider.selectAlternative(1);
                          _resetZoom();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Interactive Pan & Zoom Canvas
            Expanded(
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: Center(
                      child: SvgPicture.string(
                        activePlan.svgFloorPlan,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Floating Zoom Controls
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoom_in',
                          backgroundColor: SmartPlotTheme.bgPure,
                          foregroundColor: SmartPlotTheme.navyDark,
                          elevation: 3,
                          onPressed: _zoomIn,
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoom_out',
                          backgroundColor: SmartPlotTheme.bgPure,
                          foregroundColor: SmartPlotTheme.navyDark,
                          elevation: 3,
                          onPressed: _zoomOut,
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'zoom_reset',
                          backgroundColor: SmartPlotTheme.bgPure,
                          foregroundColor: SmartPlotTheme.navyDark,
                          elevation: 3,
                          tooltip: 'Fit to Screen',
                          onPressed: _resetZoom,
                          child: const Icon(Icons.fit_screen_outlined),
                        ),
                      ],
                    ),
                  ),

                  // Compass & Orientation Pill
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SmartPlotTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation, size: 14, color: SmartPlotTheme.errorRed),
                          const SizedBox(width: 4),
                          Text(
                            'Entrance: ${provider.input.entranceOrientation}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SmartPlotTheme.navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mandatory Disclaimer Banner
            DisclaimerBanner(
              customText: provider.latestResult?.disclaimer,
            ),
          ],
        ),
      ),
    );
  }
}
