import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  // Configured default LAN IP of your host PC (allows physical Android device like Motorola to connect over Wi-Fi)
  static String _serverHost = '172.17.83.174:5000';

  // Configured Gemini AI API key for intelligence dispatch & Copilot reasoning
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get serverHost => _serverHost;

  static void setServerHost(String host) {
    if (host.trim().isNotEmpty) {
      _serverHost = host.trim().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/api/?$'), '');
    }
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // On physical Android device or emulator, route to the configured host PC
    return 'http://$_serverHost/api';
  }

  static String get socketUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://$_serverHost';
  }
}
