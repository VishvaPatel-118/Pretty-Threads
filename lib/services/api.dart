import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://129fe27032d1.ngrok-free.app';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // Register user
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? fullAddress,
    String? city,
    String? pincode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');

    final body = {
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber ?? '',
      'password': password,
      'password_confirmation': password,
      'full_address': fullAddress ?? '',
      'city': city ?? '',
      'pincode': pincode ?? '',
    };

    final resp = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);

    if (resp.statusCode == 201) {
      return data as Map<String, dynamic>;
    }

    // Try to extract validation errors or message
    final message = _extractErrorMessage(data) ?? 'Registration failed (${resp.statusCode})';
    throw Exception(message);
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    final resp = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);

    if (resp.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    final message = _extractErrorMessage(data) ?? 'Login failed (${resp.statusCode})';
    throw Exception(message);
  }

  static dynamic _parseJson(http.Response resp) {
    try {
      if (resp.body.isEmpty) return {};
      return jsonDecode(resp.body);
    } catch (_) {
      return {'raw': resp.body};
    }
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Top-level message if available (e.g., "Validation failed")
      final topMessage = data['message'] is String ? data['message'] as String : null;

      // Field-specific errors
      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;
        final msgs = <String>[];

        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String) msgs.add('$key: $first');
          } else if (value is String && value.isNotEmpty) {
            msgs.add('$key: $value');
          }
        });

        if (msgs.isNotEmpty) {
          final parts = <String>[];
          if (topMessage != null && topMessage.isNotEmpty) parts.add(topMessage);
          parts.addAll(msgs);
          return parts.join('\n');
        }
      }

      // Fallback to just the top-level message
      if (topMessage != null && topMessage.isNotEmpty) return topMessage;
    }
    return null;
  }

  // ===== Protected endpoints (Profile) =====
  static Future<Map<String, dynamic>> getProfile({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/user');
    final resp = await http
        .get(uri, headers: _authHeaders(token))
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);
    if (resp.statusCode == 200) return data as Map<String, dynamic>;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to fetch profile (${resp.statusCode})');
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? fullAddress,
    String? city,
    String? pincode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user');
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (email != null) payload['email'] = email;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (fullAddress != null) payload['full_address'] = fullAddress;
    if (city != null) payload['city'] = city;
    if (pincode != null) payload['pincode'] = pincode;

    final resp = await http
        .put(
          uri,
          headers: _authHeaders(token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    final data = _parseJson(resp);
    if (resp.statusCode == 200) return data as Map<String, dynamic>;
    throw Exception(_extractErrorMessage(data) ?? 'Failed to update profile (${resp.statusCode})');
  }

  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user/password');
    final resp = await http
        .put(
          uri,
          headers: _authHeaders(token),
          body: jsonEncode({
            'current_password': currentPassword,
            'password': newPassword,
            'password_confirmation': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 200) return;
    final data = _parseJson(resp);
    throw Exception(_extractErrorMessage(data) ?? 'Failed to change password (${resp.statusCode})');
  }
}
