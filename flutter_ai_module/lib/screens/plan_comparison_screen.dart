library plan_comparison_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import 'detailed_plan_viewer_screen.dart';

class PlanComparisonScreen extends StatelessWidget {
  const PlanComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final result = provider.latestResult;

    if (result == null || result.alternatives.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Design Comparison')),
        body: const Center(child: Text('Dual design alternatives not available.')),
      );
    }

    final planA = result.alternatives[0];
    final planB = result.alternatives[1];

    final sbA = planA.spatialBreakdown;
    final sbB = planB.spatialBreakdown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan A vs Plan B Comparison'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'ARCHITECTURAL COMPARISON MATRIX',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            // Comparison Table Card
            Container(
              decoration: BoxDecoration(
                color: SmartPlotTheme.bgPure,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SmartPlotTheme.borderLight),
              ),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1.1),
                  2: FlexColumnWidth(1.1),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: SmartPlotTheme.borderLight.withValues(alpha: 0.6), width: 1),
                ),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      color: SmartPlotTheme.bgSurface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Attribute',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: SmartPlotTheme.navyDark),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Plan A\n(Open Living)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: SmartPlotTheme.primaryEmerald),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Plan B\n(Privacy Focused)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ),
                  _buildMetricRow('Design Theme', 'Open Social Flow', 'Formal Segregation'),
                  _buildMetricRow('Guest Entrance', 'Direct into Lounge', 'Formal Drawing Room'),
                  _buildMetricRow('Net Room Area', '${sbA.netRoomArea.toStringAsFixed(1)} ft²', '${sbB.netRoomArea.toStringAsFixed(1)} ft²'),
                  _buildMetricRow('Circulation Area', '${sbA.circulationArea.toStringAsFixed(1)} ft²', '${sbB.circulationArea.toStringAsFixed(1)} ft²'),
                  _buildMetricRow('Wall Footprint', '${sbA.wallArea.toStringAsFixed(1)} ft²', '${sbB.wallArea.toStringAsFixed(1)} ft²'),
                  _buildMetricRow('Total Covered', '${sbA.totalCoveredArea.toStringAsFixed(1)} ft²', '${sbB.totalCoveredArea.toStringAsFixed(1)} ft²'),
                  _buildMetricRow('Footprint Util.', '${sbA.utilizationPercentage.toStringAsFixed(0)}%', '${sbB.utilizationPercentage.toStringAsFixed(0)}%'),
                  _buildMetricRow('Rooms Count', '${planA.rooms.length}', '${planB.rooms.length}'),
                  _buildMetricRow('Doors Installed', '${planA.doors.length}', '${planB.doors.length}'),
                  _buildMetricRow('Exterior Windows', '${planA.windows.length}', '${planB.windows.length}'),
                  _buildMetricRow('Reachability', '100% BFS Valid', '100% BFS Valid'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Concept Trade-offs
            const Text(
              'CONCEPT ANALYSIS & BEST FIT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            _buildTradeoffCard(
              title: 'Plan A — Open Living Concept',
              concept: 'Interconnected Social Hub',
              idealFor: 'Modern nuclear families who prioritize spaciousness, visual connectivity between cooking and living, and maximum daylight.',
              color: SmartPlotTheme.primaryEmerald,
              isSelected: provider.selectedAlternativeIndex == 0,
              onSelect: () {
                provider.selectAlternative(0);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailedPlanViewerScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildTradeoffCard(
              title: 'Plan B — Privacy Focused',
              concept: 'Traditional Cultural Segregation',
              idealFor: 'Multi-generational Pakistani households requiring an independent guest drawing room (baithak) to preserve acoustic and visual family privacy.',
              color: const Color(0xFF6366F1),
              isSelected: provider.selectedAlternativeIndex == 1,
              onSelect: () {
                provider.selectAlternative(1);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailedPlanViewerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static TableRow _buildMetricRow(String label, String valA, String valB) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SmartPlotTheme.navyDark),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            valA,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: SmartPlotTheme.navyText),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            valB,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: SmartPlotTheme.navyText),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeoffCard({
    required String title,
    required String concept,
    required String idealFor,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmartPlotTheme.bgPure,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : SmartPlotTheme.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SELECTED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            concept,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SmartPlotTheme.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            idealFor,
            style: const TextStyle(
              fontSize: 11,
              color: SmartPlotTheme.slateMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.fullscreen, size: 16),
            label: Text('Open $title in Detailed Viewer'),
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}
