import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  // Login method
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      if (response.statusCode == 200) {
        final data = response.data;
        await saveToken(data['access_token']);
        await saveUserData(data['user']);
        return data;
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
    return null;
  }

  // Logout method
  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await _apiService.logout(token);
        await clearToken();
      } catch (e) {
        throw Exception('Failed to logout: $e');
      }
    }
  }

  // Save token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Get token securely
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Verify token
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear token and user data
  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  // Save user data securely
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: 'user_data', value: jsonString);
  }

  // Get user data securely
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: 'user_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }
}
