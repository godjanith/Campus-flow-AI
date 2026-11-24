import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AppConfig {
  // Default to USB ADB Reverse proxy (127.0.0.1:5000) for physical Android devices plugged in via USB
  static String _serverHost = '127.0.0.1:5000';

  // Configured Gemini AI API key for intelligence dispatch & Copilot reasoning
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get serverHost => _serverHost;

  static void setServerHost(String host) {
    if (host.trim().isNotEmpty) {
      _serverHost = host.trim().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/api/?$'), '');
    }
  }

  // Auto-probes active host endpoints:
  // 1) 127.0.0.1:5000 (USB ADB reverse proxy for physical device)
  // 2) 172.17.83.174:5000 (Wi-Fi LAN)
  // 3) 10.0.2.2:5000 (Standard Android Emulator)
  static Future<String> autoDetectActiveHost() async {
    if (kIsWeb) {
      _serverHost = 'localhost:5000';
      return _serverHost;
    }

    final candidateHosts = [
      '127.0.0.1:5000',     // USB cable reverse
      '172.17.83.174:5000', // Wi-Fi LAN
      '10.0.2.2:5000',      // Emulator loopback
    ];

    for (final host in candidateHosts) {
      try {
        final res = await http
            .get(Uri.parse('http://$host/api/health'))
            .timeout(const Duration(milliseconds: 1000));
        if (res.statusCode == 200) {
          _serverHost = host;
          return host;
        }
      } catch (_) {}
    }

    return _serverHost;
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://$_serverHost/api';
  }

  static String get socketUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://$_serverHost';
  }
}
