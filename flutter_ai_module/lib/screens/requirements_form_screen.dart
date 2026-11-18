library requirements_form_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/plot_input.dart';
import '../providers/plan_provider.dart';
import 'loading_generation_screen.dart';

class RequirementsFormScreen extends StatefulWidget {
  const RequirementsFormScreen({super.key});

  @override
  State<RequirementsFormScreen> createState() => _RequirementsFormScreenState();
}

class _RequirementsFormScreenState extends State<RequirementsFormScreen> {
  // Single-floor state (when floors == 1)
  int _bedrooms = 2;
  int _bathrooms = 2;
  int _floors = 1;
  bool _kitchen = true;
  bool _livingRoom = true;
  bool _parking = true;

  // Floor-specific state (when floors == 2)
  int _groundBedrooms = 1;
  int _groundBathrooms = 1;
  bool _groundKitchen = true;
  bool _groundDrawingRoom = true;

  int _firstBedrooms = 2;
  int _firstBathrooms = 2;
  bool _firstLivingRoom = true;
  bool _firstTerrace = true;

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

    if (p.groundFloor != null) {
      _groundBedrooms = p.groundFloor!.bedrooms;
      _groundBathrooms = p.groundFloor!.bathrooms;
      _groundKitchen = p.groundFloor!.kitchen;
      _groundDrawingRoom = p.groundFloor!.drawingRoom;
    }
    if (p.firstFloor != null) {
      _firstBedrooms = p.firstFloor!.bedrooms;
      _firstBathrooms = p.firstFloor!.bathrooms;
      _firstLivingRoom = p.firstFloor!.livingRoom;
      _firstTerrace = p.firstFloor!.terrace;
    }
  }

  void _triggerGeneration() {
    final provider = context.read<PlanProvider>();
    FloorRequirementModel? gf;
    FloorRequirementModel? ff;
    int totalBeds = _bedrooms;
    int totalBaths = _bathrooms;

    if (_floors == 2) {
      gf = FloorRequirementModel(
        bedrooms: _groundBedrooms,
        bathrooms: _groundBathrooms,
        kitchen: _groundKitchen,
        livingRoom: true,
        drawingRoom: _groundDrawingRoom,
        terrace: false,
      );
      ff = FloorRequirementModel(
        bedrooms: _firstBedrooms,
        bathrooms: _firstBathrooms,
        kitchen: false,
        livingRoom: _firstLivingRoom,
        drawingRoom: false,
        terrace: _firstTerrace,
      );
      totalBeds = _groundBedrooms + _firstBedrooms;
      totalBaths = _groundBathrooms + _firstBathrooms;

      if (totalBeds < 1 || totalBeds > 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total bedrooms across Ground and First Floor must be between 1 and 6.'),
            backgroundColor: SmartPlotTheme.errorRed,
          ),
        );
        return;
      }
      if (totalBaths < 1 || totalBaths > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total bathrooms across Ground and First Floor must be between 1 and 5.'),
            backgroundColor: SmartPlotTheme.errorRed,
          ),
        );
        return;
      }
    }

    provider.updateRequirements(
      bedrooms: totalBeds,
      bathrooms: totalBaths,
      floors: _floors,
      kitchen: _kitchen,
      livingRoom: _livingRoom,
      parking: _parking,
      groundFloor: gf,
      firstFloor: ff,
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
                  const Icon(Icons.crop_free, size: 20, color: SmartPlotTheme.primaryEmerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plot.plotWidth.toStringAsFixed(0)} × ${plot.plotLength.toStringAsFixed(0)} ${plot.unit} • Facing ${plot.entranceOrientation}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: SmartPlotTheme.navyDark),
                        ),
                        Text(
                          'Total Area: ${(plot.plotWidth * plot.plotLength).toStringAsFixed(0)} sq ${plot.unit}',
                          style: const TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Multi-Floor Tile
            _buildFloorTile(),
            const SizedBox(height: 20),

            if (_floors == 1) ...[
              // Single Floor Room Counts Section
              const Text(
                'SINGLE FLOOR ROOM ALLOCATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmartPlotTheme.slateLight, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              _buildCounterTile(
                label: 'Bedrooms',
                subtitle: 'Master and secondary family bedrooms',
                icon: Icons.bed_outlined,
                value: _bedrooms,
                min: 1,
                max: 4,
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
            ] else ...[
              // Two Floors — Independent Floor Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INDEPENDENT FLOOR SPECIFICATIONS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmartPlotTheme.slateLight, letterSpacing: 0.8),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: SmartPlotTheme.primaryEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TOTAL: ${_groundBedrooms + _firstBedrooms} BEDS • ${_groundBathrooms + _firstBathrooms} BATHS',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SmartPlotTheme.primaryEmerald),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ground Floor Section Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SmartPlotTheme.bgPure,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SmartPlotTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: SmartPlotTheme.emeraldSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.foundation, size: 16, color: SmartPlotTheme.primaryEmerald),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GROUND FLOOR',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SmartPlotTheme.navyDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCounterTile(
                      label: 'Ground Bedrooms',
                      subtitle: 'Master bedroom or guest suite',
                      icon: Icons.bed_outlined,
                      value: _groundBedrooms,
                      min: 0,
                      max: 2,
                      onChanged: (v) => setState(() => _groundBedrooms = v),
                    ),
                    const SizedBox(height: 8),
                    _buildCounterTile(
                      label: 'Ground Bathrooms',
                      subtitle: 'Attached bath / powder room',
                      icon: Icons.bathtub_outlined,
                      value: _groundBathrooms,
                      min: 1,
                      max: 2,
                      onChanged: (v) => setState(() => _groundBathrooms = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: 'Ground Kitchen',
                      subtitle: 'Main ground-level cooking kitchen',
                      icon: Icons.countertops_outlined,
                      value: _groundKitchen,
                      onChanged: (v) => setState(() => _groundKitchen = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: 'Drawing Room / Baithak',
                      subtitle: 'Formal front guest reception room',
                      icon: Icons.chair_outlined,
                      value: _groundDrawingRoom,
                      onChanged: (v) => setState(() => _groundDrawingRoom = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // First Floor Section Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SmartPlotTheme.bgPure,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SmartPlotTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: SmartPlotTheme.slateLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.apartment, size: 16, color: SmartPlotTheme.navyDark),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'FIRST FLOOR',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SmartPlotTheme.navyDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCounterTile(
                      label: 'First Floor Bedrooms',
                      subtitle: 'Family bedrooms with rear/side light',
                      icon: Icons.bed_outlined,
                      value: _firstBedrooms,
                      min: 1,
                      max: 3,
                      onChanged: (v) => setState(() => _firstBedrooms = v),
                    ),
                    const SizedBox(height: 8),
                    _buildCounterTile(
                      label: 'First Floor Bathrooms',
                      subtitle: 'Ensuite and family shared baths',
                      icon: Icons.bathtub_outlined,
                      value: _firstBathrooms,
                      min: 1,
                      max: 3,
                      onChanged: (v) => setState(() => _firstBathrooms = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: 'Upper TV Lounge',
                      subtitle: 'Central first-floor family sitting area',
                      icon: Icons.weekend_outlined,
                      value: _firstLivingRoom,
                      onChanged: (v) => setState(() => _firstLivingRoom = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: 'Front Open Terrace',
                      subtitle: 'Upper open terrace above car porch',
                      icon: Icons.deck_outlined,
                      value: _firstTerrace,
                      onChanged: (v) => setState(() => _firstTerrace = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _buildSwitchTile(
                title: 'Car Porch & Parking',
                subtitle: 'Front parking bay connected to road entrance',
                icon: Icons.directions_car_outlined,
                value: _parking,
                onChanged: (v) => setState(() => _parking = v),
              ),
            ],

            const SizedBox(height: 28),

            // Action Button
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: Text(_floors == 2 ? 'Generate Multi-Floor Plans' : 'Generate AI Floor Plans'),
              onPressed: _triggerGeneration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SmartPlotTheme.bgPure,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _floors == 2 ? SmartPlotTheme.primaryEmerald.withValues(alpha: 0.5) : SmartPlotTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _floors == 2
                      ? SmartPlotTheme.emeraldSubtle
                      : SmartPlotTheme.slateLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  size: 20,
                  color: _floors == 2 ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.navyDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Number of Floors',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: SmartPlotTheme.navyDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _floors == 2 ? SmartPlotTheme.emeraldSubtle : SmartPlotTheme.borderLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _floors == 2 ? '2 Floors (G+1)' : '1 (Ground Only)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _floors == 2 ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _floors == 2
                          ? 'Ground Floor + First Floor with vertical staircase core'
                          : 'Single-story ground floor plan layout',
                      style: const TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Interactive 1 Floor / 2 Floors selector
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Text(
                      '1 Floor (Ground)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  selected: _floors == 1,
                  selectedColor: SmartPlotTheme.emeraldSubtle,
                  onSelected: (selected) {
                    if (selected) setState(() => _floors = 1);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Text(
                      '2 Floors (G+1)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  selected: _floors == 2,
                  selectedColor: SmartPlotTheme.emeraldSubtle,
                  onSelected: (selected) {
                    if (selected) setState(() => _floors = 2);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SmartPlotTheme.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SmartPlotTheme.borderLight),
            ),
            child: Row(
              children: [
                Icon(
                  _floors == 2 ? Icons.check_circle_outline : Icons.info_outline,
                  size: 14,
                  color: _floors == 2 ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _floors == 2
                        ? 'Phase 6 Multi-Floor Engine: Generates Ground Floor + First Floor with 100% vertical staircase alignment, upper lounge, and front open terrace.'
                        : 'Single-level design optimized for single-story villas, bungalows, or initial floor planning.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _floors == 2 ? SmartPlotTheme.navyDark : SmartPlotTheme.slateMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
