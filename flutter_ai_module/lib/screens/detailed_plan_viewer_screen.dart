library detailed_plan_viewer_screen;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/room_list_bottom_sheet.dart';
import 'edit_floor_plan_screen.dart';

class DetailedPlanViewerScreen extends StatefulWidget {
  const DetailedPlanViewerScreen({super.key});

  @override
  State<DetailedPlanViewerScreen> createState() => _DetailedPlanViewerScreenState();
}

class _DetailedPlanViewerScreenState extends State<DetailedPlanViewerScreen> {
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;
  int _selectedFloor = 1;

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
    final activePlan = provider.selectedAlternative;
    final isMultiFloor = activePlan?.floorsCount == 2;

    if (!isMultiFloor) {
      final path = await provider.saveCurrentPlanLocally();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor plan SVG saved to:\n$path'),
            backgroundColor: SmartPlotTheme.primaryEmerald,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Floor Plan SVG',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SmartPlotTheme.navyDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select whether to export current floor or both floors.',
                  style: TextStyle(fontSize: 12, color: SmartPlotTheme.slateMuted),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.layers_outlined, color: SmartPlotTheme.primaryEmerald),
                  title: const Text('Export Both Floors (GF + 1F)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Saves both Ground and First Floor SVGs', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final paths = await provider.saveBothFloorsLocally();
                    if (mounted && paths != null && paths.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved both floor plans:\n${paths.join("\n")}'),
                          backgroundColor: SmartPlotTheme.primaryEmerald,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(_selectedFloor == 1 ? Icons.stairs : Icons.deck_outlined, color: SmartPlotTheme.navyDark),
                  title: Text('Export Current Floor (${_selectedFloor == 1 ? "Ground" : "First"})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('Saves active ${_selectedFloor == 1 ? "Ground" : "First"} Floor vector SVG', style: const TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await provider.saveCurrentPlanLocally(floor: _selectedFloor);
                    if (mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${_selectedFloor == 1 ? "Ground" : "First"} Floor saved to:\n$path'),
                          backgroundColor: SmartPlotTheme.primaryEmerald,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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

    final isMultiFloor = activePlan.floorsCount == 2;
    String displayedSvg = activePlan.svgFloorPlan;
    if (isMultiFloor) {
      if (_selectedFloor == 1 && activePlan.svgGroundFloor != null) {
        displayedSvg = activePlan.svgGroundFloor!;
      } else if (_selectedFloor == 2 && activePlan.svgFirstFloor != null) {
        displayedSvg = activePlan.svgFirstFloor!;
      }
    }

    final floorRooms = isMultiFloor
        ? activePlan.rooms.where((r) => r.floor == _selectedFloor).toList()
        : activePlan.rooms;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isMultiFloor
              ? '${activePlan.title} (${_selectedFloor == 1 ? "Ground" : "First"} Floor)'
              : activePlan.title,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: SmartPlotTheme.primaryEmerald),
            tooltip: 'Interactive Plan Editor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditFloorPlanScreen(initialFloor: _selectedFloor),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export SVG locally',
            onPressed: _exportPlan,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Plan SVG',
            onPressed: () async {
              final provider = context.read<PlanProvider>();
              await provider.shareCurrentPlan(floor: isMultiFloor ? _selectedFloor : null);
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Room Schedule',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => RoomListBottomSheet(
                  rooms: floorRooms,
                  circulationPaths: activePlan.circulationPaths,
                  planTitle: isMultiFloor
                      ? '${activePlan.title} — ${_selectedFloor == 1 ? "Ground Floor" : "First Floor"}'
                      : activePlan.title,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Plan Selector and Floor Selector Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SmartPlotTheme.bgSurface,
              child: Column(
                children: [
                  SingleChildScrollView(
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
                  if (isMultiFloor) ...[
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            avatar: Icon(
                              Icons.stairs,
                              size: 14,
                              color: _selectedFloor == 1 ? Colors.white : SmartPlotTheme.primaryEmerald,
                            ),
                            label: const Text('Ground Floor (GF)'),
                            selected: _selectedFloor == 1,
                            selectedColor: SmartPlotTheme.primaryEmerald,
                            labelStyle: TextStyle(
                              color: _selectedFloor == 1 ? Colors.white : SmartPlotTheme.navyDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedFloor = 1);
                                _resetZoom();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: Icon(
                              Icons.deck,
                              size: 14,
                              color: _selectedFloor == 2 ? Colors.white : SmartPlotTheme.primaryEmerald,
                            ),
                            label: const Text('First Floor (1F)'),
                            selected: _selectedFloor == 2,
                            selectedColor: SmartPlotTheme.primaryEmerald,
                            labelStyle: TextStyle(
                              color: _selectedFloor == 2 ? Colors.white : SmartPlotTheme.navyDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedFloor = 2);
                                _resetZoom();
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: SmartPlotTheme.emeraldSubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '3D Staircase Aligned',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: SmartPlotTheme.primaryEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                        displayedSvg,
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
                          heroTag: 'reset_zoom',
                          backgroundColor: SmartPlotTheme.bgPure,
                          foregroundColor: SmartPlotTheme.navyDark,
                          elevation: 3,
                          onPressed: _resetZoom,
                          child: const Icon(Icons.center_focus_strong),
                        ),
                      ],
                    ),
                  ),

                  // Current Zoom Level Indicator
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: SmartPlotTheme.navyDark.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Zoom: ${(_currentScale * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mandatory Disclaimer at footer
            const DisclaimerBanner(),
          ],
        ),
      ),
    );
  }
}
