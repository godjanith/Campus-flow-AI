import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  // --- SET THIS TO YOUR MACHINE'S LAN IP FOR PHYSICAL DEVICE TESTING ---
  static const String _lanOverride = '';

  // Configured Gemini AI API key for intelligence dispatch & Copilot reasoning
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get baseUrl {
    if (_lanOverride.isNotEmpty) {
      return 'http://$_lanOverride:5000/api';
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static String get socketUrl {
    if (_lanOverride.isNotEmpty) {
      return 'http://$_lanOverride:5000';
    }
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }
}
