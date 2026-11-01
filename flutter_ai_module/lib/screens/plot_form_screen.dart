library plot_form_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/plot_input.dart';
import '../providers/plan_provider.dart';
import 'requirements_form_screen.dart';

class PlotFormScreen extends StatefulWidget {
  const PlotFormScreen({super.key});

  @override
  State<PlotFormScreen> createState() => _PlotFormScreenState();
}

class _PlotFormScreenState extends State<PlotFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _frontController;

  late TextEditingController _frontSetbackController;
  late TextEditingController _rearSetbackController;
  late TextEditingController _sideSetbackController;

  String _orientation = 'South';
  String _unit = 'feet';
  bool _showSetbacks = false;

  final List<String> _orientations = [
    'South',
    'North',
    'East',
    'West',
    'SE',
    'SW',
    'NE',
    'NW',
  ];

  @override
  void initState() {
    super.initState();
    final p = context.read<PlanProvider>().input;
    _lengthController = TextEditingController(text: p.plotLength.toStringAsFixed(1));
    _widthController = TextEditingController(text: p.plotWidth.toStringAsFixed(1));
    _frontController = TextEditingController(text: p.frontWidth.toStringAsFixed(1));

    _frontSetbackController = TextEditingController(text: p.setbacks?.front.toStringAsFixed(1) ?? '0.0');
    _rearSetbackController = TextEditingController(text: p.setbacks?.rear.toStringAsFixed(1) ?? '0.0');
    _sideSetbackController = TextEditingController(text: p.setbacks?.left.toStringAsFixed(1) ?? '0.0');

    _orientation = p.entranceOrientation;
    _unit = p.unit;
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _frontController.dispose();
    _frontSetbackController.dispose();
    _rearSetbackController.dispose();
    _sideSetbackController.dispose();
    super.dispose();
  }

  void _applyPreset(double l, double w, double f) {
    setState(() {
      _lengthController.text = l.toStringAsFixed(1);
      _widthController.text = w.toStringAsFixed(1);
      _frontController.text = f.toStringAsFixed(1);
    });
  }

  void _saveAndProceed() {
    if (_formKey.currentState?.validate() ?? false) {
      final length = double.parse(_lengthController.text);
      final width = double.parse(_widthController.text);
      final front = double.parse(_frontController.text);

      SetbacksModel? setbacks;
      if (_showSetbacks) {
        setbacks = SetbacksModel(
          front: double.tryParse(_frontSetbackController.text) ?? 0.0,
          rear: double.tryParse(_rearSetbackController.text) ?? 0.0,
          left: double.tryParse(_sideSetbackController.text) ?? 0.0,
          right: double.tryParse(_sideSetbackController.text) ?? 0.0,
        );
      }

      context.read<PlanProvider>().updatePlotInput(
            plotLength: length,
            plotWidth: width,
            frontWidth: front,
            entranceOrientation: _orientation,
            unit: _unit,
            setbacks: setbacks,
          );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RequirementsFormScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plot Measurements'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                      'STEP 1 OF 2',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Plot Boundaries & Orientation',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SmartPlotTheme.navyDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Presets
              const Text(
                'STANDARD PAKISTANI PLOTS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmartPlotTheme.slateLight, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('5 Marla (25×45)', 45.0, 25.0, 25.0),
                    _buildPresetChip('5 Marla Modern (25×50)', 50.0, 25.0, 25.0),
                    _buildPresetChip('10 Marla (35×65)', 65.0, 35.0, 35.0),
                    _buildPresetChip('1 Kanal (50×90)', 90.0, 50.0, 50.0),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Unit Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: SmartPlotTheme.borderLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _unit = 'feet'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _unit == 'feet' ? SmartPlotTheme.bgPure : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _unit == 'feet'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Feet (ft)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _unit == 'feet' ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _unit = 'meters'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _unit == 'meters' ? SmartPlotTheme.bgPure : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _unit == 'meters'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Meters (m)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _unit == 'meters' ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.slateMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Plot Dimensions Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lengthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Plot Length ($_unit)',
                        hintText: 'e.g. 45.0',
                        prefixIcon: const Icon(Icons.straighten, size: 20),
                      ),
                      validator: (value) {
                        final val = double.tryParse(value ?? '');
                        if (val == null || val <= 0) return 'Required > 0';
                        if (val < 15.0) return 'Min 15 $_unit';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Plot Width ($_unit)',
                        hintText: 'e.g. 25.0',
                        prefixIcon: const Icon(Icons.width_normal, size: 20),
                      ),
                      onChanged: (val) {
                        // Keep front width synced if it was matching
                        final w = double.tryParse(val);
                        if (w != null && _frontController.text.isEmpty) {
                          _frontController.text = val;
                        }
                      },
                      validator: (value) {
                        final val = double.tryParse(value ?? '');
                        if (val == null || val <= 0) return 'Required > 0';
                        if (val < 10.0) return 'Min 10 $_unit';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _frontController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Front Road Width ($_unit)',
                  hintText: 'e.g. 25.0',
                  prefixIcon: const Icon(Icons.front_hand_outlined, size: 20),
                  helperText: 'Must not exceed the total plot width.',
                ),
                validator: (value) {
                  final front = double.tryParse(value ?? '');
                  final width = double.tryParse(_widthController.text);
                  if (front == null || front <= 0) return 'Required > 0';
                  if (width != null && front > width) {
                    return 'Front width cannot exceed total plot width ($width $_unit)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Orientation Dropdown
              const Text(
                'MAIN ENTRANCE ORIENTATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SmartPlotTheme.slateLight, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _orientations.map((orient) {
                  final isSelected = _orientation == orient;
                  return ChoiceChip(
                    label: Text(orient),
                    selected: isSelected,
                    selectedColor: SmartPlotTheme.emeraldSubtle,
                    backgroundColor: SmartPlotTheme.bgPure,
                    labelStyle: TextStyle(
                      color: isSelected ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.navyDark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? SmartPlotTheme.primaryEmerald : SmartPlotTheme.borderLight,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _orientation = orient);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Municipal Setbacks Section
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Specify Municipal Setbacks (Optional)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SmartPlotTheme.navyDark),
                ),
                subtitle: const Text(
                  'Reserve unbuilt buffer along plot boundaries for bylaws.',
                  style: TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted),
                ),
                value: _showSetbacks,
                activeColor: SmartPlotTheme.primaryEmerald,
                onChanged: (val) => setState(() => _showSetbacks = val ?? false),
              ),

              if (_showSetbacks) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _frontSetbackController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Front Setback ($_unit)',
                          hintText: 'e.g. 5.0',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _rearSetbackController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Rear Setback ($_unit)',
                          hintText: 'e.g. 5.0',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sideSetbackController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Side Setbacks ($_unit)',
                    hintText: 'e.g. 0.0 or 3.0',
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Action Button
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next: Room Requirements'),
                onPressed: _saveAndProceed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double l, double w, double f) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: SmartPlotTheme.bgPure,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: SmartPlotTheme.borderLight),
        ),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SmartPlotTheme.navyDark),
        onPressed: () => _applyPreset(l, w, f),
      ),
    );
  }
}
