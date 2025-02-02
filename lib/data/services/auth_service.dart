import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  Future<AuthResponse> login(String email, String password) async {
    try {
      print('Attempting to login with URL: ${ApiConstants.baseUrl}/auth/login');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return AuthResponse.fromJson(jsonDecode(response.body));
      
    } catch (e) {
      print('Login error: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<AuthResponse> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));

        // Simpan token
        if (authResponse.token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', authResponse.token!);
        }

        return authResponse;
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } finally {
        await prefs.remove('token');
      }
    }
  }
}
