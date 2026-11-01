library plan_results_screen;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/metric_card.dart';
import '../widgets/room_list_bottom_sheet.dart';
import 'detailed_plan_viewer_screen.dart';
import 'plan_comparison_screen.dart';

class PlanResultsScreen extends StatelessWidget {
  const PlanResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final result = provider.latestResult;
    final activePlan = provider.selectedAlternative;

    if (result == null || activePlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Floor Plan Results')),
        body: const Center(child: Text('No floor plan data available.')),
      );
    }

    final sb = activePlan.spatialBreakdown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Floor Plan Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare Plan A vs B',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlanComparisonScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Save / Export Plan',
            onPressed: () async {
              final path = await provider.saveCurrentPlanLocally();
              if (context.mounted && path != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Plan saved successfully to $path'),
                    backgroundColor: SmartPlotTheme.primaryEmerald,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            // Plan Selector Segment Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SmartPlotTheme.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => provider.selectAlternative(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: provider.selectedAlternativeIndex == 0
                              ? SmartPlotTheme.bgPure
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: provider.selectedAlternativeIndex == 0
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Plan A: Open Living',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: provider.selectedAlternativeIndex == 0
                                ? SmartPlotTheme.primaryEmerald
                                : SmartPlotTheme.slateMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => provider.selectAlternative(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: provider.selectedAlternativeIndex == 1
                              ? SmartPlotTheme.bgPure
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: provider.selectedAlternativeIndex == 1
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Plan B: Privacy Focused',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: provider.selectedAlternativeIndex == 1
                                ? SmartPlotTheme.primaryEmerald
                                : SmartPlotTheme.slateMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Plan Title & Concept Description Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SmartPlotTheme.bgPure,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SmartPlotTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activePlan.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SmartPlotTheme.navyDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activePlan.isFeasible
                              ? SmartPlotTheme.emeraldSubtle
                              : SmartPlotTheme.errorBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activePlan.isFeasible ? 'VERIFIED FEASIBLE' : 'INFEASIBLE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: activePlan.isFeasible
                                ? SmartPlotTheme.primaryEmerald
                                : SmartPlotTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activePlan.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SmartPlotTheme.slateMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Floor Plan Preview Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailedPlanViewerScreen()),
                );
              },
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SmartPlotTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: SvgPicture.string(
                          activePlan.svgFloorPlan,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: SmartPlotTheme.navyDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Inspect Fullscreen',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Primary Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.zoom_in, size: 18),
                    label: const Text('Detailed Viewer'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DetailedPlanViewerScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('Room Schedule'),
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
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spatial Breakdown Metrics
            const Text(
              'SPATIAL ACCOUNTING & BREAKDOWN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Total Covered Area',
                    value: '${sb.totalCoveredArea.toStringAsFixed(1)} ft²',
                    subtitle: '${sb.utilizationPercentage.toStringAsFixed(1)}% footprint',
                    icon: Icons.square_foot,
                    accentColor: SmartPlotTheme.primaryEmerald,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Net Room Area',
                    value: '${sb.netRoomArea.toStringAsFixed(1)} ft²',
                    subtitle: 'Usable carpet area',
                    icon: Icons.meeting_room_outlined,
                    accentColor: const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Circulation Corridors',
                    value: '${sb.circulationArea.toStringAsFixed(1)} ft²',
                    subtitle: 'Foyers & galleries',
                    icon: Icons.alt_route,
                    accentColor: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    label: 'Structural Walls',
                    value: '${sb.wallArea.toStringAsFixed(1)} ft²',
                    subtitle: '9" ext / 4.5" int',
                    icon: Icons.foundation,
                    accentColor: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AI Recommendations Section
            if (activePlan.recommendations.isNotEmpty) ...[
              const Text(
                'AI DESIGN RECOMMENDATIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SmartPlotTheme.slateLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              ...activePlan.recommendations.map((rec) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SmartPlotTheme.bgPure,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SmartPlotTheme.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18, color: SmartPlotTheme.primaryEmerald),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rec.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: SmartPlotTheme.navyDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rec.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: SmartPlotTheme.slateMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],

            // SP-AI-10 Mandatory Disclaimer Banner
            DisclaimerBanner(customText: result.disclaimer.isNotEmpty ? result.disclaimer : null),
          ],
        ),
      ),
    );
  }
}
