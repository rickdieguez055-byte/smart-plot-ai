library ai_planning_home_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import 'plot_form_screen.dart';
import 'settings_screen.dart';
import 'plan_results_screen.dart';

class AiPlanningHomeScreen extends StatelessWidget {
  const AiPlanningHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SmartPlotTheme.primaryEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.architecture, color: SmartPlotTheme.primaryEmerald, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('SmartPlot AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Gateway Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Gateway Status Indicator
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: provider.isGatewayHealthy
                      ? SmartPlotTheme.emeraldSubtle
                      : SmartPlotTheme.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.isGatewayHealthy
                        ? SmartPlotTheme.emeraldLight.withValues(alpha: 0.5)
                        : SmartPlotTheme.warningAmber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.isGatewayHealthy ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: provider.isGatewayHealthy
                          ? SmartPlotTheme.primaryEmerald
                          : SmartPlotTheme.warningAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.isGatewayHealthy
                            ? 'Gateway Connected: ${provider.currentBaseUrl}'
                            : 'Gateway Disconnected: Tap to configure URL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.isGatewayHealthy
                              ? SmartPlotTheme.primaryEmerald
                              : SmartPlotTheme.warningAmber,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: SmartPlotTheme.slateMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hero Brand Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: SmartPlotTheme.primaryEmerald.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AI PLOT ANALYSIS MODULE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Architectural Floor Plan\nGeneration System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Input plot boundaries and room requirements. The solver synthesizes verified, dual architectural layouts with genuine circulation and physical wall modeling.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: SmartPlotTheme.primaryEmerald,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Start New Floor Plan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlotFormScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Entitlement Quota Card (Task 5)
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              color: provider.canGenerateFree
                                  ? SmartPlotTheme.primaryEmerald
                                  : SmartPlotTheme.warningAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'Free AI Generations',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: SmartPlotTheme.navyDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.canGenerateFree
                              ? SmartPlotTheme.emeraldSubtle
                              : SmartPlotTheme.warningBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${provider.remainingFreeGenerations} / 2 Available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: provider.canGenerateFree
                                ? SmartPlotTheme.primaryEmerald
                                : SmartPlotTheme.warningAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: provider.usedGenerations / 2.0,
                    backgroundColor: SmartPlotTheme.bgSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      provider.canGenerateFree
                          ? SmartPlotTheme.primaryEmerald
                          : SmartPlotTheme.warningAmber,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FYP Prototype Tier: The first 2 AI layouts are provided free of charge for evaluation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: SmartPlotTheme.slateMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // If a plan was previously generated, show quick access card
            if (provider.latestResult != null) ...[
              const Text(
                'ACTIVE GENERATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SmartPlotTheme.slateLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlanResultsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SmartPlotTheme.bgPure,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SmartPlotTheme.primaryEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SmartPlotTheme.emeraldSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.apartment, color: SmartPlotTheme.primaryEmerald, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.selectedAlternative?.title ?? 'Generated Floor Plan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: SmartPlotTheme.navyDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Plot: ${provider.input.plotLength} × ${provider.input.plotWidth} ft • ${provider.input.bedrooms} Beds, ${provider.input.bathrooms} Baths',
                              style: const TextStyle(
                                fontSize: 12,
                                color: SmartPlotTheme.slateMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: SmartPlotTheme.slateMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Feature Highlights
            const Text(
              'ENGINE CAPABILITIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              icon: Icons.layers_outlined,
              color: const Color(0xFF6366F1),
              title: 'Dual Design Alternatives',
              description: 'Generates both Plan A (Open Living) and Plan B (Privacy Focused) from the same plot metrics.',
            ),
            const SizedBox(height: 8),
            _buildFeatureTile(
              icon: Icons.meeting_room_outlined,
              color: const Color(0xFF0284C7),
              title: 'Automated Doors & Fenestration',
              description: 'Doorway cutouts with swing arcs and exterior windows positioned on perimeter walls.',
            ),
            const SizedBox(height: 8),
            _buildFeatureTile(
              icon: Icons.calculate_outlined,
              color: const Color(0xFFD97706),
              title: 'Conservation Area Accounting',
              description: 'Accurate separation of net carpet area, true circulation hallways, and structural wall footprint.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SmartPlotTheme.bgPure,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SmartPlotTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: SmartPlotTheme.navyDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
  }
}
