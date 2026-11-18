library plan_storage_service;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SavedPlanItem {
  final String fileName;
  final String filePath;
  final String title;
  final DateTime savedAt;
  final int fileSizeBytes;

  const SavedPlanItem({
    required this.fileName,
    required this.filePath,
    required this.title,
    required this.savedAt,
    this.fileSizeBytes = 0,
  });
}

class PlanStorageService {
  static const MethodChannel _channel = MethodChannel('com.smartplot.ai/share');

  /// Resolves the storage directory for SmartPlot floor plan SVGs
  static Directory getStorageDirectory() {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Priority 1: Public Download folder on Android
        final downloadDir = Directory('/sdcard/Download/SmartPlot');
        try {
          if (!downloadDir.existsSync()) {
            downloadDir.createSync(recursive: true);
          }
          return downloadDir;
        } catch (_) {}

        // Priority 2: App files directory
        final appFilesDir = Directory('/data/user/0/com.smartplot.ai.smartplot_ai_app/files/SmartPlot');
        try {
          if (!appFilesDir.existsSync()) {
            appFilesDir.createSync(recursive: true);
          }
          return appFilesDir;
        } catch (_) {}

        // Priority 3: systemTemp
        final temp = Directory('${Directory.systemTemp.path}/SmartPlot');
        if (!temp.existsSync()) temp.createSync(recursive: true);
        return temp;
      }

      // Windows / Desktop / Other OS
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (home != null) {
        final docs = Directory('$home/Documents/SmartPlot');
        if (!docs.existsSync()) {
          docs.createSync(recursive: true);
        }
        return docs;
      }
    } catch (e) {
      debugPrint('[PlanStorageService] Error resolving directory: $e');
    }

    final fallback = Directory('${Directory.systemTemp.path}/SmartPlot');
    if (!fallback.existsSync()) fallback.createSync(recursive: true);
    return fallback;
  }

  /// Exports SVG floor plan to persistent storage
  static Future<String> saveFloorPlanSvg({
    required String planId,
    required String title,
    required String svgContent,
  }) async {
    try {
      final directory = getStorageDirectory();
      final sanitizedTitle = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      final fileName = 'smartplot_${planId}_$sanitizedTitle.svg';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(svgContent);
      debugPrint('[PlanStorageService] Floor plan saved successfully to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[PlanStorageService] Error saving floor plan: $e');
      throw Exception('Failed to save floor plan locally: $e');
    }
  }

  /// Exports both Ground Floor and First Floor SVGs for multi-floor house plans
  static Future<List<String>> saveBothFloorsSvgs({
    required String planId,
    required String title,
    required String groundFloorSvg,
    required String firstFloorSvg,
  }) async {
    try {
      final pathGround = await saveFloorPlanSvg(
        planId: planId,
        title: '${title}_ground_floor',
        svgContent: groundFloorSvg,
      );
      final pathFirst = await saveFloorPlanSvg(
        planId: planId,
        title: '${title}_first_floor',
        svgContent: firstFloorSvg,
      );
      debugPrint('[PlanStorageService] Both floors saved: $pathGround, $pathFirst');
      return [pathGround, pathFirst];
    } catch (e) {
      debugPrint('[PlanStorageService] Error saving both floors: $e');
      throw Exception('Failed to save both floor plans locally: $e');
    }
  }

  /// Lists saved floor plans from disk
  static Future<List<SavedPlanItem>> listSavedPlans() async {
    try {
      final directory = getStorageDirectory();
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
              title: name.replaceAll('.svg', '').replaceAll('smartplot_', '').replaceAll('_', ' ').toUpperCase(),
              savedAt: stat.modified,
              fileSizeBytes: stat.size,
            ),
          );
        }
      }

      items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return items;
    } catch (e) {
      debugPrint('[PlanStorageService] Error listing saved plans: $e');
      return [];
    }
  }

  /// Shares a saved floor plan SVG via Android Native Share Sheet
  static Future<void> shareFloorPlan({
    required String filePath,
    required String title,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Target floor plan file does not exist at $filePath');
      }

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _channel.invokeMethod('shareFile', {
          'filePath': filePath,
          'title': title,
        });
      } else {
        debugPrint('[PlanStorageService] Sharing on desktop/web: $filePath');
      }
    } catch (e) {
      debugPrint('[PlanStorageService] Share failed: $e');
      throw Exception('Failed to share floor plan: $e');
    }
  }

  /// Reads the SVG content of a previously saved floor plan
  static Future<String?> readSavedSvg(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('[PlanStorageService] Read saved SVG failed: $e');
      return null;
    }
  }

  /// Deletes a previously saved floor plan
  static Future<bool> deleteSavedPlan(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[PlanStorageService] Delete saved plan failed: $e');
      return false;
    }
  }

  /// Persists full editable geometry and metadata as JSON plus exports the SVG
  static Future<String> saveEditedPlanPackage({
    required String planId,
    required String customName,
    required Map<String, dynamic> planDataJson,
    required String svgContent,
  }) async {
    try {
      final directory = getStorageDirectory();
      final sanitized = customName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      final baseFileName = 'smartplot_edited_${planId}_$sanitized';

      // 1. Save JSON with full structured editable geometry
      final jsonFile = File('${directory.path}/$baseFileName.json');
      await jsonFile.writeAsString(jsonEncode({
        'custom_name': customName,
        'saved_at': DateTime.now().toIso8601String(),
        'plan_id': planId,
        'package_version': '1.0',
        'is_edited': true,
        'data': planDataJson,
      }));

      // 2. Also save matching SVG for vector viewing
      final svgFile = File('${directory.path}/$baseFileName.svg');
      await svgFile.writeAsString(svgContent);

      debugPrint('[PlanStorageService] Saved edited plan package to: ${jsonFile.path}');
      return jsonFile.path;
    } catch (e) {
      debugPrint('[PlanStorageService] Failed to save edited plan package: $e');
      throw Exception('Failed to save edited floor plan: $e');
    }
  }

  /// Loads previously saved edited plan JSON package
  static Future<Map<String, dynamic>?> loadEditedPlanPackage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[PlanStorageService] Failed to load edited plan package: $e');
      return null;
    }
  }
}
