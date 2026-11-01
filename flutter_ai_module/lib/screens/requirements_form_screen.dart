library requirements_form_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/plan_provider.dart';
import 'loading_generation_screen.dart';

class RequirementsFormScreen extends StatefulWidget {
  const RequirementsFormScreen({super.key});

  @override
  State<RequirementsFormScreen> createState() => _RequirementsFormScreenState();
}

class _RequirementsFormScreenState extends State<RequirementsFormScreen> {
  int _bedrooms = 2;
  int _bathrooms = 2;
  int _floors = 1;
  bool _kitchen = true;
  bool _livingRoom = true;
  bool _parking = true;

  @override
  void initState() {
    super.initState();
    final p = context.read<PlanProvider>().input;
    _bedrooms = p.bedrooms;
    _bathrooms = p.bathrooms;
    _floors = p.floors;
    _kitchen = p.kitchen;
    _livingRoom = p.livingRoom;
    _parking = p.parking;
  }

  void _triggerGeneration() {
    final provider = context.read<PlanProvider>();
    provider.updateRequirements(
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      floors: _floors,
      kitchen: _kitchen,
      livingRoom: _livingRoom,
      parking: _parking,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoadingGenerationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final plot = provider.input;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Requirements'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Step indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SmartPlotTheme.primaryEmerald,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'STEP 2 OF 2',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Spaces & Spatial Requirements',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SmartPlotTheme.navyDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plot Quick Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SmartPlotTheme.bgPure,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SmartPlotTheme.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SmartPlotTheme.emeraldSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.aspect_ratio, color: SmartPlotTheme.primaryEmerald, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plot.plotLength.toStringAsFixed(1)} × ${plot.plotWidth.toStringAsFixed(1)} ${plot.unit}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: SmartPlotTheme.navyDark),
                        ),
                        Text(
                          'Total Area: ${plot.totalArea.toStringAsFixed(1)} ${plot.unit}² • Facing ${plot.entranceOrientation}',
                          style: const TextStyle(fontSize: 12, color: SmartPlotTheme.slateMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Steppers
            _buildCounterTile(
              label: 'Bedrooms',
              subtitle: 'Sleeping suites (Master & secondary bedrooms)',
              icon: Icons.bed_outlined,
              value: _bedrooms,
              min: 1,
              max: 5,
              onChanged: (v) => setState(() => _bedrooms = v),
            ),
            const SizedBox(height: 12),

            _buildCounterTile(
              label: 'Bathrooms',
              subtitle: 'Ensuite and common guest powder baths',
              icon: Icons.bathtub_outlined,
              value: _bathrooms,
              min: 1,
              max: 4,
              onChanged: (v) => setState(() => _bathrooms = v),
            ),
            const SizedBox(height: 12),

            _buildCounterTile(
              label: 'Number of Floors',
              subtitle: 'Ground floor only or ground + upper level',
              icon: Icons.layers_outlined,
              value: _floors,
              min: 1,
              max: 2,
              onChanged: (v) => setState(() => _floors = v),
            ),
            const SizedBox(height: 20),

            // Core Amenities Switches
            const Text(
              'ESSENTIAL AMENITIES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmartPlotTheme.slateLight, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            _buildSwitchTile(
              title: 'Kitchen',
              subtitle: 'Independent cooking & food preparation area',
              icon: Icons.countertops_outlined,
              value: _kitchen,
              onChanged: (v) => setState(() => _kitchen = v),
            ),
            const SizedBox(height: 8),

            _buildSwitchTile(
              title: 'Living Room / TV Lounge',
              subtitle: 'Central family social gathering space',
              icon: Icons.weekend_outlined,
              value: _livingRoom,
              onChanged: (v) => setState(() => _livingRoom = v),
            ),
            const SizedBox(height: 8),

            _buildSwitchTile(
              title: 'Car Porch & Parking',
              subtitle: 'Front parking bay connected to road entrance',
              icon: Icons.directions_car_outlined,
              value: _parking,
              onChanged: (v) => setState(() => _parking = v),
            ),

            const SizedBox(height: 28),

            // Action Button
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate AI Floor Plans'),
              onPressed: _triggerGeneration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SmartPlotTheme.bgPure,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SmartPlotTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SmartPlotTheme.primaryEmerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: SmartPlotTheme.primaryEmerald),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: SmartPlotTheme.navyDark),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: value > min ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateLight,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SmartPlotTheme.navyDark),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: value < max ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateLight,
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SmartPlotTheme.bgPure,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SmartPlotTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SmartPlotTheme.slateLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: SmartPlotTheme.navyDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: SmartPlotTheme.navyDark),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: SmartPlotTheme.primaryEmerald,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
