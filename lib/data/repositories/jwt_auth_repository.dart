import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/repositories.dart';

class JwtAuthRepositoryImpl implements AuthRepository {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  
  // In production, use your actual backend URL
  static const String _baseUrl = 'https://your-api.com/api';
  
  final http.Client _client = http.Client();

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userData = data['user'];
        
        // Save token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(userData));
        
        return UserEntity(
          id: userData['id'],
          username: userData['username'],
          email: userData['email'],
          password: '', // Don't store password
        );
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': user.username,
          'email': user.email,
          'password': user.password,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userData = data['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, json.encode(userData));
        
        return UserEntity(
          id: userData['id'],
          username: userData['username'],
          email: userData['email'],
          password: '',
        );
      }
      throw Exception('Registration failed');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    
    if (token != null && userJson != null) {
      final userData = json.decode(userJson);
      return UserEntity(
        id: userData['id'],
        username: userData['username'],
        email: userData['email'],
        password: '',
      );
    }
    return null;
  }

  // Get token for API requests
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send reset email');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/check-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      final data = json.decode(response.body);
      return data['exists'] ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> updatePassword(String email, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': newPassword}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update password');
      }
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }
}