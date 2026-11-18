library saved_plans_bottom_sheet;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/theme.dart';
import '../services/plan_storage_service.dart';

class SavedPlansBottomSheet extends StatefulWidget {
  const SavedPlansBottomSheet({super.key});

  @override
  State<SavedPlansBottomSheet> createState() => _SavedPlansBottomSheetState();
}

class _SavedPlansBottomSheetState extends State<SavedPlansBottomSheet> {
  List<SavedPlanItem> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final items = await PlanStorageService.listSavedPlans();
    if (mounted) {
      setState(() {
        _plans = items;
        _isLoading = false;
      });
    }
  }

  void _previewPlan(SavedPlanItem item) async {
    final svg = await PlanStorageService.readSavedSvg(item.filePath);
    if (!mounted || svg == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.architecture, color: SmartPlotTheme.primaryEmerald, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    tooltip: 'Share Plan',
                    onPressed: () => PlanStorageService.shareFloorPlan(
                      filePath: item.filePath,
                      title: item.title,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 450),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: SvgPicture.string(svg, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'File: ${item.filePath}',
                style: const TextStyle(fontSize: 10, color: SmartPlotTheme.slateMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: SmartPlotTheme.primaryEmerald.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_open, color: SmartPlotTheme.primaryEmerald, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Saved Floor Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: SmartPlotTheme.navyDark),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Locally saved SVG floor plans on this device. Tap to reopen and inspect.',
            style: TextStyle(fontSize: 12, color: SmartPlotTheme.slateMuted),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_plans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.description_outlined, size: 48, color: SmartPlotTheme.slateLight.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No floor plans saved yet.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SmartPlotTheme.navyDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Generate a layout and tap Export / Save to access it here.',
                      style: TextStyle(fontSize: 12, color: SmartPlotTheme.slateMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final item = _plans[index];
                  final sizeKb = (item.fileSizeBytes / 1024).toStringAsFixed(1);
                  final dateStr = '${item.savedAt.year}-${item.savedAt.month.toString().padLeft(2, '0')}-${item.savedAt.day.toString().padLeft(2, '0')} ${item.savedAt.hour.toString().padLeft(2, '0')}:${item.savedAt.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SmartPlotTheme.emeraldSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.architecture, color: SmartPlotTheme.primaryEmerald, size: 22),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: SmartPlotTheme.navyDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$dateStr • $sizeKb KB • SVG',
                      style: const TextStyle(fontSize: 11, color: SmartPlotTheme.slateMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18, color: SmartPlotTheme.primaryEmerald),
                          tooltip: 'Reopen Plan',
                          onPressed: () => _previewPlan(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18, color: SmartPlotTheme.navyDark),
                          tooltip: 'Share Plan',
                          onPressed: () => PlanStorageService.shareFloorPlan(
                            filePath: item.filePath,
                            title: item.title,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: SmartPlotTheme.errorRed),
                          tooltip: 'Delete Plan',
                          onPressed: () async {
                            final deleted = await PlanStorageService.deleteSavedPlan(item.filePath);
                            if (deleted) _loadPlans();
                          },
                        ),
                      ],
                    ),
                    onTap: () => _previewPlan(item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
