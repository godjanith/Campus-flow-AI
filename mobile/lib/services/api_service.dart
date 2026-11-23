import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/ticket.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 8);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token'] as String);
        await prefs.setString('user_data', jsonEncode(data));
        return data;
      } else {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Login failed. Please verify credentials.');
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) rethrow;
          throw Exception('Login failed (${response.statusCode})');
        }
      }
    } on SocketException {
      throw Exception('Server unreachable at ${AppConfig.baseUrl}. Ensure backend is running on port 5000, or tap "Explore as Demo Student".');
    } on http.ClientException {
      throw Exception('Connection failed to backend. Tap "Explore as Demo Student" to test immediately.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? regNo,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
              'regNo': (regNo != null && regNo.trim().isNotEmpty) ? regNo.trim() : '20252MCA0318',
              'role': 'STUDENT',
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token'] as String);
        await prefs.setString('user_data', jsonEncode(data));
        return data;
      } else {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Registration failed');
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) rethrow;
          throw Exception('Registration failed (${response.statusCode})');
        }
      }
    } on SocketException {
      throw Exception('Server unreachable at ${AppConfig.baseUrl}. Ensure backend is running on port 5000, or tap "Explore as Demo Student".');
    } on http.ClientException {
      throw Exception('Connection failed to backend. Tap "Explore as Demo Student" to test immediately.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> demoLogin({
    String name = 'Janith V C',
    String email = 'student@presidencyuniversity.in',
    String regNo = '20252MCA0318',
  }) async {
    final data = {
      '_id': 'demo_user_20252MCA0318',
      'name': name,
      'email': email,
      'role': 'STUDENT',
      'regNo': regNo,
      'token': 'demo_jwt_token_campusflow_2026',
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', data['token'] as String);
    await prefs.setString('user_data', jsonEncode(data));
    return data;
  }

  static Future<List<Ticket>> getTickets() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}/tickets'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load tickets');
    }
  }

  static Future<Ticket> createTicket({
    required String title,
    required String description,
    String? building,
    double? lat,
    double? lng,
    String? reporterName,
    String? reporterRegNo,
    File? image,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('${AppConfig.baseUrl}/tickets');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['title'] = title;
    request.fields['description'] = description;
    if (building != null) request.fields['building'] = building;
    if (lat != null) request.fields['lat'] = lat.toString();
    if (lng != null) request.fields['lng'] = lng.toString();
    if (reporterName != null) request.fields['reporterName'] = reporterName;
    if (reporterRegNo != null) request.fields['reporterRegNo'] = reporterRegNo;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Ticket.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create ticket');
    }
  }

  static Future<Map<String, dynamic>> chatWithCopilot(String message) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/tickets/chat'),
          headers: headers,
          body: jsonEncode({'message': message}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('AI Copilot request failed');
    }
  }

  static Future<Map<String, dynamic>> getCampusHealthScore() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('${AppConfig.baseUrl}/tickets/health-score'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load health score');
    }
  }

  static Future<Ticket> updateTicketStatus(String ticketId, String status, {String? note}) async {
    final headers = await _authHeaders();
    final response = await http
        .patch(
          Uri.parse('${AppConfig.baseUrl}/tickets/$ticketId/status'),
          headers: headers,
          body: jsonEncode({
            'status': status,
            if (note != null) 'note': note,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return Ticket.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to update ticket status');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final token = prefs.getString('jwt_token');
    if (userData != null && token != null) {
      return jsonDecode(userData) as Map<String, dynamic>;
    }
    return null;
  }
}
