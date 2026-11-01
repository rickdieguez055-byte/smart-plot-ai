library room_list_bottom_sheet;

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/floor_plan_result.dart';

class RoomListBottomSheet extends StatelessWidget {
  final List<RoomModel> rooms;
  final List<CirculationPathModel> circulationPaths;
  final String planTitle;

  const RoomListBottomSheet({
    super.key,
    required this.rooms,
    required this.circulationPaths,
    required this.planTitle,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bedroom':
        return Icons.bed_outlined;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'kitchen':
        return Icons.countertops_outlined;
      case 'living':
        return Icons.weekend_outlined;
      case 'parking':
        return Icons.directions_car_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'bedroom':
        return const Color(0xFF4F46E5);
      case 'bathroom':
        return const Color(0xFF0891B2);
      case 'kitchen':
        return const Color(0xFFD97706);
      case 'living':
        return const Color(0xFF0284C7);
      case 'parking':
        return const Color(0xFF475569);
      default:
        return SmartPlotTheme.primaryEmerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SmartPlotTheme.bgPure,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SmartPlotTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Architectural Room Schedule',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: SmartPlotTheme.navyDark,
                    ),
                  ),
                  Text(
                    planTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SmartPlotTheme.slateMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'ROOMS & SPACES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SmartPlotTheme.slateLight,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ...rooms.map((room) {
                  final color = _getCategoryColor(room.category);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SmartPlotTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SmartPlotTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_getCategoryIcon(room.category), size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: SmartPlotTheme.navyText,
                                ),
                              ),
                              Text(
                                '${room.width.toStringAsFixed(1)} × ${room.length.toStringAsFixed(1)} ft',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SmartPlotTheme.slateMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${room.area.toStringAsFixed(1)} ft²',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: SmartPlotTheme.navyDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (circulationPaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'CIRCULATION CORRIDORS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SmartPlotTheme.slateLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...circulationPaths.map((cp) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SmartPlotTheme.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SmartPlotTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: SmartPlotTheme.slateLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.alt_route, size: 18, color: SmartPlotTheme.slateMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cp.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: SmartPlotTheme.navyText,
                                  ),
                                ),
                                Text(
                                  'Width: ${cp.width.toStringAsFixed(1)} ft | Depth: ${cp.length.toStringAsFixed(1)} ft',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: SmartPlotTheme.slateMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${cp.area.toStringAsFixed(1)} ft²',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: SmartPlotTheme.navyDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
