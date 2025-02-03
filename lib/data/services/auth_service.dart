import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../../core/constants/api_constants.dart';
import 'dart:io';

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

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String idUnit,
    required String nik,
    required File fotoKtp,
    required String alamatAsal,
    required String nomorWa,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/register'),
    );

    // Tambahkan fields
    request.fields.addAll({
      'name': name,
      'email': email,
      'password': password,
      'id_unit': idUnit,
      'nik': nik,
      'alamat_asal': alamatAsal,
      'nomor_wa': nomorWa,
    });

    // Tambahkan file foto KTP
    request.files.add(await http.MultipartFile.fromPath(
      'foto_ktp',
      fotoKtp.path,
    ));

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      return AuthResponse(
        status: jsonResponse['status'],
        message: jsonResponse['message'],
        token: jsonResponse['token'],
        user: jsonResponse['user'],
      );
    } catch (e) {
      throw Exception('Registration failed: $e');
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

  Future<List<Map<String, dynamic>>> getKamarTersedia() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/unit-kamar/available'), // Sesuaikan dengan endpoint API
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Gagal memuat data kamar');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
