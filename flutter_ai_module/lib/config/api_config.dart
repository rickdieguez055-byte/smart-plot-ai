library api_config;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const int requestTimeoutSeconds = 45;

  /// Default local gateway port
  static const int defaultPort = 5000;

  /// Determines default base URL based on runtime platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$defaultPort';
    }
    try {
      if (Platform.isIOS) {
        // On iOS physical devices, 127.0.0.1 refers to the iPhone itself.
        // Default to the local Wi-Fi IP of the host development computer
        return 'http://192.168.18.11:$defaultPort';
      }
      if (Platform.isAndroid) {
        // Physical devices with `adb reverse tcp:5000 tcp:5000` connect via 127.0.0.1.
        // For emulators, 10.0.2.2 is also available in the presets.
        return 'http://127.0.0.1:$defaultPort';
      }
    } catch (_) {}
    return 'http://127.0.0.1:$defaultPort';
  }

  /// Preset environment URLs for quick switching in UI
  static const List<Map<String, String>> presets = [
    {
      'label': 'Local Wi-Fi Host (192.168.18.11:5000)',
      'url': 'http://192.168.18.11:5000',
    },
    {
      'label': 'Physical Device USB Reverse (127.0.0.1:5000)',
      'url': 'http://127.0.0.1:5000',
    },
    {
      'label': 'Cloud HTTPS Gateway (https://api.smartplot.ai)',
      'url': 'https://api.smartplot.ai',
    },
    {
      'label': 'Android Emulator (10.0.2.2:5000)',
      'url': 'http://10.0.2.2:5000',
    },
    {
      'label': 'Localhost / Windows Desktop (127.0.0.1:5000)',
      'url': 'http://127.0.0.1:5000',
    },
    {
      'label': 'Direct AI Microservice (127.0.0.1:8000)',
      'url': 'http://127.0.0.1:8000',
    },
  ];
}
