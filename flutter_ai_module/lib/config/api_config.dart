library api_config;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const int requestTimeoutSeconds = 15;

  /// Default local gateway port
  static const int defaultPort = 5000;

  /// Determines default base URL based on runtime platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator loops back to host machine at 10.0.2.2
        return 'http://10.0.2.2:$defaultPort';
      }
    } catch (_) {}
    return 'http://127.0.0.1:$defaultPort';
  }

  /// Preset environment URLs for quick switching in UI
  static const List<Map<String, String>> presets = [
    {
      'label': 'Android Emulator (10.0.2.2:5000)',
      'url': 'http://10.0.2.2:5000',
    },
    {
      'label': 'Localhost / Windows Desktop (127.0.0.1:5000)',
      'url': 'http://127.0.0.1:5000',
    },
    {
      'label': 'Direct AI Backend (127.0.0.1:8000)',
      'url': 'http://127.0.0.1:8000',
    },
  ];
}
