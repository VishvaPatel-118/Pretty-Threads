import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_threads/services/api.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  bool get isAdmin {
    final u = _user;
    if (u == null) return false;
    final role = (u['role'] ?? u['user_role'] ?? '').toString().toLowerCase();
    final isAdminFlag = u['is_admin'] == true || u['admin'] == true;
    return isAdminFlag || role == 'admin';
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final rawUser = prefs.getString('auth_user');
    if (rawUser != null) {
      try {
        _user = jsonDecode(rawUser) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user));
  }

  Future<void> loadProfile() async {
    await loadFromStorage();
    if (!isLoggedIn) return;
    final data = await ApiService.getProfile(token: _token!);
    // Backend may return { user: {...} } or direct fields
    final u = (data['user'] ?? data) as Map<String, dynamic>;
    await saveUser(u);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _user = null;
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}
