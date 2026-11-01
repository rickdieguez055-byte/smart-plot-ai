library settings_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testStatus;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<PlanProvider>().currentBaseUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testStatus = null;
    });

    final provider = context.read<PlanProvider>();
    provider.updateBaseUrl(_urlController.text);
    await provider.checkHealth();

    setState(() {
      _isTesting = false;
      _testStatus = provider.isGatewayHealthy
          ? 'Gateway is reachable & healthy!'
          : 'Gateway connection failed. Please verify that Node.js Gateway & FastAPI backend are running.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gateway & App Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Text(
              'API GATEWAY CONFIGURATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Base URL field
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Gateway Base URL',
                hintText: 'http://10.0.2.2:5000',
                prefixIcon: Icon(Icons.dns_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),

            // Environment Presets
            const Text(
              'QUICK PRESETS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            ...ApiConfig.presets.map((preset) {
              final isCurrent = _urlController.text.trim() == preset['url'];
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isCurrent ? SmartPlotTheme.emeraldSubtle : SmartPlotTheme.bgPure,
                    side: BorderSide(
                      color: isCurrent ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.borderLight,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () {
                    setState(() => _urlController.text = preset['url']!);
                  },
                  child: Row(
                    children: [
                      Icon(
                        isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 16,
                        color: isCurrent ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          preset['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.navyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Test Connection Button
            ElevatedButton.icon(
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.network_check, size: 18),
              label: Text(_isTesting ? 'Testing Connectivity...' : 'Save & Test Connection'),
              onPressed: _isTesting ? null : _testConnection,
            ),

            if (_testStatus != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: provider.isGatewayHealthy ? SmartPlotTheme.emeraldSubtle : SmartPlotTheme.errorBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: provider.isGatewayHealthy ? SmartPlotTheme.emeraldLight : SmartPlotTheme.errorRed,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.isGatewayHealthy ? Icons.check_circle : Icons.error,
                      size: 18,
                      color: provider.isGatewayHealthy ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.errorRed,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.isGatewayHealthy ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Entitlement Settings (Task 5)
            const Text(
              'PROTOTYPE ENTITLEMENT CONTROLS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SmartPlotTheme.slateLight,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Generations Used:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: SmartPlotTheme.navyDark),
                      ),
                      Text(
                        '${provider.usedGenerations} of 2',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: SmartPlotTheme.primaryEmerald),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'In production, subscription and generation quotas are backed by Cloud Firestore and Firebase Auth rules. For university evaluation, you may reset the generation counter below.',
                    style: TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Free Generations for Testing'),
                    onPressed: () {
                      provider.resetPrototypeTier();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Free generations quota reset to 2.'),
                          backgroundColor: SmartPlotTheme.primaryEmerald,
                        ),
                      );
                    },
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
