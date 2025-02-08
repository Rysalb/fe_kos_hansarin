import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../../core/constants/api_constants.dart';
import 'dart:io';
import 'package:intl/intl.dart';


class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
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

      print('Login response status: ${response.statusCode}'); // Debugging
      print('Login response body: ${response.body}'); // Debugging

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['token'] != null) {
          // Simpan token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('user_role', data['user']['role']);
          
          print('Token stored: ${data['token']}'); // Debugging
          print('Role stored: ${data['user']['role']}'); // Debugging
        }
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Login gagal');
      }
    } catch (e) {
      print('Login error: $e'); // Debugging
      throw Exception('Error: $e');
    }
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    print('Retrieved role: $role'); // Debugging
    return role == 'admin';
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
    final token = prefs.getString(_tokenKey);

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
        await prefs.remove(_tokenKey);
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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved token: $token'); // Debugging
    return token;
  }

  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/role/$role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(responseData['data']);
          // Filter hanya user dengan status verifikasi pending
          return users.where((user) => 
            user['status_verifikasi'] == 'pending' || 
            user['status_verifikasi'] == null
          ).toList();
        }
        return [];
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> verifikasiUser(
    int userId,
    String status,
    DateTime? tanggalMasuk,
    int? durasiSewa,
    double? hargaSewa,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verifikasi-user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'tanggal_masuk': tanggalMasuk?.toIso8601String(),
          'durasi_sewa': durasiSewa,
          'harga_sewa': hargaSewa,
        }),
      );

      print('Verifikasi response: ${response.body}'); // Debug print

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memverifikasi user');
      }
    } catch (e) {
      print('Error in verifikasiUser: $e'); // Debug print
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      print('Fetching profile with token: $token'); // Debug print

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile'), // Update URL sesuai route baru
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Profile response status: ${response.statusCode}'); // Debug print
      print('Profile response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return responseData['data'];
        }
        throw Exception('Data profil tidak ditemukan');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memuat profil');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Error: $e');
    }
  }
}
