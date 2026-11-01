library plan_storage_service;

import 'dart:io';

class SavedPlanItem {
  final String fileName;
  final String filePath;
  final String title;
  final DateTime savedAt;

  const SavedPlanItem({
    required this.fileName,
    required this.filePath,
    required this.title,
    required this.savedAt,
  });
}

class PlanStorageService {
  /// Exports SVG floor plan to a file in application documents / temporary storage
  static Future<String> saveFloorPlanSvg({
    required String planId,
    required String title,
    required String svgContent,
  }) async {
    try {
      Directory directory;
      try {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (home != null) {
          final docs = Directory('$home/Documents/SmartPlot');
          if (!docs.existsSync()) {
            docs.createSync(recursive: true);
          }
          directory = docs;
        } else {
          directory = Directory.systemTemp;
        }
      } catch (_) {
        directory = Directory.systemTemp;
      }

      final sanitizedTitle = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      final fileName = 'smartplot_${planId}_$sanitizedTitle.svg';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(svgContent);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save floor plan locally: $e');
    }
  }

  /// Lists saved floor plans from disk
  static Future<List<SavedPlanItem>> listSavedPlans() async {
    try {
      Directory directory;
      try {
        final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (home != null) {
          directory = Directory('$home/Documents/SmartPlot');
        } else {
          directory = Directory.systemTemp;
        }
      } catch (_) {
        directory = Directory.systemTemp;
      }

      if (!directory.existsSync()) return [];

      final List<SavedPlanItem> items = [];
      final files = directory.listSync();

      for (var f in files) {
        if (f is File && f.path.endsWith('.svg') && f.path.contains('smartplot_')) {
          final name = f.uri.pathSegments.last;
          final stat = f.statSync();
          items.add(
            SavedPlanItem(
              fileName: name,
              filePath: f.path,
              title: name.replaceAll('.svg', '').replaceAll('smartplot_', ''),
              savedAt: stat.modified,
            ),
          );
        }
      }

      items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return items;
    } catch (_) {
      return [];
    }
  }
}
