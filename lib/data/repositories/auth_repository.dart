import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../../core/constants/api_constants.dart';

class AuthRepository {
  final http.Client client;

  AuthRepository({http.Client? client}) : client = client ?? http.Client();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/login'),
        body: {
          'email': email,
          'password': password,
        },
      );
      
      return AuthResponse.fromJson(jsonDecode(response.body));
    } catch (e) {
      throw Exception('Failed to login');
    }
  }

  // Implementasi method lainnya (register, logout, dll)
} 