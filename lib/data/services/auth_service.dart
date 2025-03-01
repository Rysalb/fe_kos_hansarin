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

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['token'] != null) {
        // Save all necessary user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_role', data['user']['role']);
        
        // Save penyewa ID if user is a penyewa
        if (data['user']['role'] == 'user' && data['penyewa'] != null) {
          await prefs.setInt('id_penyewa', data['penyewa']['id_penyewa']);
        }

        print('Stored user data:'); // Debug prints
        print('Token: ${data['token']}');
        print('Role: ${data['user']['role']}');
        print('Penyewa ID: ${data['penyewa']?['id_penyewa']}');
      }
      return data;
    } catch (e) {
      print('Login error: $e');
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

    request.fields.addAll({
      'name': name,
      'email': email,
      'password': password,
      'id_unit': idUnit,
      'nik': nik,
      'alamat_asal': alamatAsal,
      'nomor_wa': nomorWa,
    });

    request.files.add(await http.MultipartFile.fromPath(
      'foto_ktp',
      fotoKtp.path,
    ));

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      return AuthResponse(
        status: jsonResponse['status'] ?? false,
        message: jsonResponse['message'] ?? 'Unknown error',
        token: jsonResponse['token'],
        user: jsonResponse['user'] != null ? UserModel.fromJson(jsonResponse['user']) : null,
      );
    } catch (e) {
      print('Registration error: $e');
      throw Exception(e.toString());
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

  Future<Map<String, dynamic>> verifikasiUser(
    int userId,
    String status,
    DateTime? tanggalMasuk,
    int? durasiSewa,
    double? hargaSewa,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final Map<String, dynamic> body = {
        'status': status,
      };

      // Only add these fields if status is 'disetujui'
      if (status == 'disetujui') {
        body['tanggal_masuk'] = DateFormat('yyyy-MM-dd').format(tanggalMasuk!);
        body['durasi_sewa'] = durasiSewa;
        body['harga_sewa'] = hargaSewa;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verifikasi-user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return json.decode(response.body);
    } catch (e) {
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

  Future<Map<String, dynamic>> registerAdmin({
  required String name,
  required String email,
  required String password,
  required String nomorWa,
  required String passwordConfirmation,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/register-admin'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'nomor_wa': nomorWa,
        'password_confirmation': passwordConfirmation,
      }),
    );

    return json.decode(response.body);
  } catch (e) {
    throw Exception('Failed to register admin: $e');
  }
}

  Future<List<Map<String, dynamic>>> getAdminList() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/admin-list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil data admin');
      } else {
        throw Exception('Gagal mengambil data admin');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String nomorWa,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/profile/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'nomor_wa': nomorWa,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate profile');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> sendResetPasswordLink() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/password/email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Reset password response: ${response.body}'); // Untuk debugging

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengirim link reset password');
      }
    } catch (e) {
      print('Reset password error: $e'); // Untuk debugging
      throw Exception('Gagal mengirim link reset password');
    }
  }
}