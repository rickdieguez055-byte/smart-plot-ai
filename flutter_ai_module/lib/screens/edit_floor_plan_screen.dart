library edit_floor_plan_screen;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/floor_plan_result.dart';
import '../models/plot_input.dart';
import '../providers/plan_provider.dart';

class EditFloorPlanScreen extends StatefulWidget {
  final int initialFloor;

  const EditFloorPlanScreen({
    super.key,
    this.initialFloor = 1,
  });

  @override
  State<EditFloorPlanScreen> createState() => _EditFloorPlanScreenState();
}

class _EditFloorPlanScreenState extends State<EditFloorPlanScreen> {
  late int _selectedFloor;
  Offset? _dragStartOffset;
  double? _roomOrigX;
  double? _roomOrigY;

  @override
  void initState() {
    super.initState();
    _selectedFloor = widget.initialFloor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlanProvider>();
      final active = provider.selectedAlternative;
      if (active != null) {
        provider.initEditingSession(active);
        provider.validateCurrentEdit(floor: _selectedFloor);
      }
    });
  }

  void _onFloorChanged(int newFloor) {
    if (_selectedFloor != newFloor) {
      setState(() => _selectedFloor = newFloor);
      final provider = context.read<PlanProvider>();
      final plan = provider.activeEditingAlternative;
      if (plan != null) {
        final floorRooms = plan.rooms.where((r) => r.floor == newFloor).toList();
        if (floorRooms.isNotEmpty) {
          provider.selectRoom(floorRooms.first.id);
        }
        provider.validateCurrentEdit(floor: newFloor);
      }
    }
  }

  Future<void> _showSaveDialog() async {
    final provider = context.read<PlanProvider>();
    final controller = TextEditingController(
      text: 'Custom Edit ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    final customName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.save_as_outlined, color: SmartPlotTheme.primaryEmerald),
              SizedBox(width: 8),
              Text('Save Custom Layout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a name for this customized floor plan layout. It will be saved with full editable geometry and an exportable SVG.',
                style: TextStyle(fontSize: 12, color: SmartPlotTheme.slateMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Layout Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save Layout'),
            ),
          ],
        );
      },
    );

    if (customName != null && customName.isNotEmpty && mounted) {
      final path = await provider.saveNamedEditedPlan(customName, floor: _selectedFloor);
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom plan saved to:\n$path'),
            backgroundColor: SmartPlotTheme.primaryEmerald,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final plan = provider.activeEditingAlternative;
    final plot = provider.input;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Floor Plan')),
        body: const Center(child: Text('No active floor plan available for editing.')),
      );
    }

    final isMultiFloor = plan.floorsCount == 2;
    final floorRooms = isMultiFloor
        ? plan.rooms.where((r) => r.floor == _selectedFloor).toList()
        : plan.rooms;
    final selectedRoom = floorRooms.firstWhere(
      (r) => r.id == provider.selectedRoomId,
      orElse: () => floorRooms.first,
    );

    final validation = provider.lastValidationResult;
    final isValid = validation?.isValid ?? true;

    return Scaffold(
      backgroundColor: SmartPlotTheme.bgSurface,
      appBar: AppBar(
        title: const Text('Interactive Floor Plan Editor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: provider.canUndo ? () => provider.undo() : null,
          ),
          IconButton(
            tooltip: 'Redo',
            icon: const Icon(Icons.redo),
            onPressed: provider.canRedo ? () => provider.redo() : null,
          ),
          IconButton(
            tooltip: 'Reset to Original AI Plan',
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              provider.resetToOriginal();
              provider.validateCurrentEdit(floor: _selectedFloor);
            },
          ),
          IconButton(
            tooltip: 'Save Custom Plan',
            icon: const Icon(Icons.save),
            onPressed: _showSaveDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls: Alternative Switcher & Floor Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: SmartPlotTheme.bgPure,
              child: Row(
                children: [
                  Expanded(
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
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              if (val) {
                                provider.selectAlternative(0);
                                final alt = provider.selectedAlternative;
                                if (alt != null) {
                                  provider.initEditingSession(alt);
                                  provider.validateCurrentEdit(floor: _selectedFloor);
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Plan B: Privacy Focused'),
                            selected: provider.selectedAlternativeIndex == 1,
                            selectedColor: const Color(0xFFEEF2FF),
                            labelStyle: TextStyle(
                              color: provider.selectedAlternativeIndex == 1
                                  ? const Color(0xFF4F46E5)
                                  : SmartPlotTheme.slateMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              if (val) {
                                provider.selectAlternative(1);
                                final alt = provider.selectedAlternative;
                                if (alt != null) {
                                  provider.initEditingSession(alt);
                                  provider.validateCurrentEdit(floor: _selectedFloor);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMultiFloor) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('GF'),
                      selected: _selectedFloor == 1,
                      selectedColor: SmartPlotTheme.primaryEmerald,
                      labelStyle: TextStyle(
                        color: _selectedFloor == 1 ? Colors.white : SmartPlotTheme.navyDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (val) => _onFloorChanged(1),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('1F'),
                      selected: _selectedFloor == 2,
                      selectedColor: SmartPlotTheme.primaryEmerald,
                      labelStyle: TextStyle(
                        color: _selectedFloor == 2 ? Colors.white : SmartPlotTheme.navyDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (val) => _onFloorChanged(2),
                    ),
                  ],
                ],
              ),
            ),

            // Live Geometry Validation Banner
            if (validation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isValid ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle_outline : Icons.error_outline,
                      color: isValid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isValid
                            ? 'Geometry Valid: Buildable boundary, minimum sizes & reachability verified.'
                            : 'Architectural Infeasibility: ${validation.rejectionReason ?? "Invalid edit."}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isValid ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Interactive Editing Canvas
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SmartPlotTheme.borderLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final canvasWidth = constraints.maxWidth;
                          final canvasHeight = constraints.maxHeight;

                          final plotW = plot.plotWidth;
                          final plotL = plot.plotLength;

                          // Scale plot to fit canvas comfortably
                          final scaleX = (canvasWidth - 40) / plotW;
                          final scaleY = (canvasHeight - 40) / plotL;
                          final scale = math.min(scaleX, scaleY);

                          final offsetX = (canvasWidth - (plotW * scale)) / 2;
                          final offsetY = (canvasHeight - (plotL * scale)) / 2;

                          return GestureDetector(
                            onTapDown: (details) {
                              final localPos = details.localPosition;
                              final plotX = (localPos.dx - offsetX) / scale;
                              final plotY = (localPos.dy - offsetY) / scale;

                              // Hit test rooms
                              for (var r in floorRooms.reversed) {
                                if (plotX >= r.x &&
                                    plotX <= (r.x + r.width) &&
                                    plotY >= r.y &&
                                    plotY <= (r.y + r.length)) {
                                  provider.selectRoom(r.id);
                                  break;
                                }
                              }
                            },
                            onPanStart: (details) {
                              _dragStartOffset = details.localPosition;
                              _roomOrigX = selectedRoom.x;
                              _roomOrigY = selectedRoom.y;
                            },
                            onPanUpdate: (details) {
                              if (_dragStartOffset == null || _roomOrigX == null || _roomOrigY == null) return;
                              final dx = (details.localPosition.dx - _dragStartOffset!.dx) / scale;
                              final dy = (details.localPosition.dy - _dragStartOffset!.dy) / scale;

                              // Snap to 0.5 ft grid
                              final newX = (_roomOrigX! + dx);
                              final snappedX = (newX * 2).roundToDouble() / 2;
                              final newY = (_roomOrigY! + dy);
                              final snappedY = (newY * 2).roundToDouble() / 2;

                              provider.updateRoomGeometry(
                                selectedRoom.id,
                                x: snappedX,
                                y: snappedY,
                                floor: _selectedFloor,
                                recordUndo: false,
                              );
                            },
                            onPanEnd: (_) {
                              _dragStartOffset = null;
                              _roomOrigX = null;
                              _roomOrigY = null;
                              // Record undo milestone and validate with backend
                              provider.updateRoomGeometry(
                                selectedRoom.id,
                                x: selectedRoom.x,
                                y: selectedRoom.y,
                                floor: _selectedFloor,
                                recordUndo: true,
                              );
                              provider.validateCurrentEdit(floor: _selectedFloor);
                            },
                            child: CustomPaint(
                              size: Size(canvasWidth, canvasHeight),
                              painter: _FloorPlanCanvasPainter(
                                plot: plot,
                                rooms: floorRooms,
                                selectedRoomId: provider.selectedRoomId,
                                conflictingRoomIds: validation?.conflictingRoomIds ?? [],
                                scale: scale,
                                offsetX: offsetX,
                                offsetY: offsetY,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Plot: ${plot.plotWidth.toInt()}×${plot.plotLength.toInt()} ft | Grid: 0.5 ft',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Properties & Dimension Control Panel
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: SmartPlotTheme.bgPure,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Room Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmartPlotTheme.emeraldSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                selectedRoom.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: SmartPlotTheme.primaryEmerald,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedRoom.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: SmartPlotTheme.navyDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedRoom.width.toStringAsFixed(1)} × ${selectedRoom.length.toStringAsFixed(1)} ft (${selectedRoom.area.toStringAsFixed(0)} ft²)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: SmartPlotTheme.slateMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Width and Length Numeric Steppers / Sliders
                  Row(
                    children: [
                      Expanded(
                        child: _DimensionControlTile(
                          label: 'Width',
                          value: selectedRoom.width,
                          min: 3.0,
                          max: 30.0,
                          step: 0.5,
                          onChanged: (val) {
                            provider.updateRoomGeometry(
                              selectedRoom.id,
                              width: val,
                              floor: _selectedFloor,
                            );
                            provider.validateCurrentEdit(floor: _selectedFloor);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DimensionControlTile(
                          label: 'Length',
                          value: selectedRoom.length,
                          min: 3.0,
                          max: 40.0,
                          step: 0.5,
                          onChanged: (val) {
                            provider.updateRoomGeometry(
                              selectedRoom.id,
                              length: val,
                              floor: _selectedFloor,
                            );
                            provider.validateCurrentEdit(floor: _selectedFloor);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Position Sliders (X and Y coordinates)
                  Row(
                    children: [
                      Expanded(
                        child: _DimensionControlTile(
                          label: 'X Position',
                          value: selectedRoom.x,
                          min: 0.0,
                          max: plot.plotWidth,
                          step: 0.5,
                          onChanged: (val) {
                            provider.updateRoomGeometry(
                              selectedRoom.id,
                              x: val,
                              floor: _selectedFloor,
                            );
                            provider.validateCurrentEdit(floor: _selectedFloor);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DimensionControlTile(
                          label: 'Y Position',
                          value: selectedRoom.y,
                          min: 0.0,
                          max: plot.plotLength,
                          step: 0.5,
                          onChanged: (val) {
                            provider.updateRoomGeometry(
                              selectedRoom.id,
                              y: val,
                              floor: _selectedFloor,
                            );
                            provider.validateCurrentEdit(floor: _selectedFloor);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Recalculate & Apply Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: provider.isValidatingEdit
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high, size: 18),
                      label: Text(
                        provider.isValidatingEdit ? 'Validating Geometry...' : 'Apply & Recalculate Layout',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: (!isValid || provider.isValidatingEdit)
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await provider.applyCurrentEdit(floor: _selectedFloor);
                              if (!mounted) return;
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Layout updated: Doors, windows, and SVG regenerated successfully!'),
                                    backgroundColor: SmartPlotTheme.primaryEmerald,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionControlTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const _DimensionControlTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SmartPlotTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SmartPlotTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: SmartPlotTheme.slateMuted, fontWeight: FontWeight.w600)),
              Text('${value.toStringAsFixed(1)} ft', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SmartPlotTheme.navyDark)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20, color: SmartPlotTheme.slateMuted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final nextVal = math.max(min, value - step);
                  onChanged(nextVal);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20, color: SmartPlotTheme.primaryEmerald),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final nextVal = math.min(max, value + step);
                  onChanged(nextVal);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloorPlanCanvasPainter extends CustomPainter {
  final PlotInput plot;
  final List<RoomModel> rooms;
  final String? selectedRoomId;
  final List<String> conflictingRoomIds;
  final double scale;
  final double offsetX;
  final double offsetY;

  _FloorPlanCanvasPainter({
    required this.plot,
    required this.rooms,
    required this.selectedRoomId,
    required this.conflictingRoomIds,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = plot.plotWidth * scale;
    final plotL = plot.plotLength * scale;

    // 1. Draw Architectural Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= plotW; x += (5.0 * scale)) {
      canvas.drawLine(Offset(offsetX + x, offsetY), Offset(offsetX + x, offsetY + plotL), gridPaint);
    }
    for (double y = 0; y <= plotL; y += (5.0 * scale)) {
      canvas.drawLine(Offset(offsetX, offsetY + y), Offset(offsetX + plotW, offsetY + y), gridPaint);
    }

    // 2. Draw Plot Boundary
    final plotPaint = Paint()
      ..color = SmartPlotTheme.navyDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(Rect.fromLTWH(offsetX, offsetY, plotW, plotL), plotPaint);

    // 3. Draw Rooms
    for (var r in rooms) {
      final isSelected = r.id == selectedRoomId;
      final isConflicting = conflictingRoomIds.contains(r.id);

      final rx = offsetX + (r.x * scale);
      final ry = offsetY + (r.y * scale);
      final rw = r.width * scale;
      final rl = r.length * scale;
      final roomRect = Rect.fromLTWH(rx, ry, rw, rl);

      // Category color mapping
      Color fillColor;
      Color strokeColor;
      Color textColor;

      final cat = r.category.toLowerCase();
      if (cat.contains('bed')) {
        fillColor = const Color(0xFFF5F3FF);
        strokeColor = const Color(0xFF4F46E5);
        textColor = const Color(0xFF312E81);
      } else if (cat.contains('bath')) {
        fillColor = const Color(0xFFECFEFF);
        strokeColor = const Color(0xFF0891B2);
        textColor = const Color(0xFF164E63);
      } else if (cat.contains('kitchen')) {
        fillColor = const Color(0xFFFFFBEB);
        strokeColor = const Color(0xFFD97706);
        textColor = const Color(0xFF78350F);
      } else if (cat.contains('stair')) {
        fillColor = const Color(0xFFFFF7ED);
        strokeColor = const Color(0xFFEA580C);
        textColor = const Color(0xFF7C2D12);
      } else if (cat.contains('terrace')) {
        fillColor = const Color(0xFFF0FDF4);
        strokeColor = const Color(0xFF16A34A);
        textColor = const Color(0xFF14532D);
      } else if (cat.contains('park') || cat.contains('porch')) {
        fillColor = const Color(0xFFF8FAFC);
        strokeColor = const Color(0xFF475569);
        textColor = const Color(0xFF1E293B);
      } else {
        fillColor = const Color(0xFFF0F9FF);
        strokeColor = const Color(0xFF0284C7);
        textColor = const Color(0xFF0C4A6E);
      }

      if (isConflicting) {
        fillColor = const Color(0xFFFEE2E2);
        strokeColor = const Color(0xFFDC2626);
      }

      // Draw Fill
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(roomRect, fillPaint);

      // Draw Stroke
      final borderPaint = Paint()
        ..color = isSelected ? SmartPlotTheme.primaryEmerald : strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.5;
      canvas.drawRect(roomRect, borderPaint);

      // Draw Corner Resize Grips if Selected
      if (isSelected) {
        final gripPaint = Paint()
          ..color = SmartPlotTheme.primaryEmerald
          ..style = PaintingStyle.fill;
        const gripRadius = 4.0;
        canvas.drawCircle(roomRect.topLeft, gripRadius, gripPaint);
        canvas.drawCircle(roomRect.topRight, gripRadius, gripPaint);
        canvas.drawCircle(roomRect.bottomLeft, gripRadius, gripPaint);
        canvas.drawCircle(roomRect.bottomRight, gripRadius, gripPaint);
      }

      // Draw Room Label and Dimensions Text
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${r.name}\n',
            style: TextStyle(
              color: isConflicting ? const Color(0xFFDC2626) : textColor,
              fontWeight: FontWeight.w800,
              fontSize: math.max(9.0, math.min(13.0, rw / 10.0)),
            ),
          ),
          TextSpan(
            text: '${r.width.toStringAsFixed(1)} × ${r.length.toStringAsFixed(1)} ft\n(${r.area.toStringAsFixed(0)} ft²)',
            style: TextStyle(
              color: isConflicting ? const Color(0xFFDC2626) : textColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: math.max(8.0, math.min(11.0, rw / 12.0)),
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: rw - 4);
      final textOffset = Offset(
        rx + (rw - textPainter.width) / 2,
        ry + (rl - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _FloorPlanCanvasPainter oldDelegate) {
    return true;
  }
}
