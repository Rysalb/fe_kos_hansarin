import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class PembayaranService {
  

  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/get/all'),
        headers: {'Accept': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat data pembayaran: ${response.body}');
      }
    } catch (e) {
      print('Error detail: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getById(int idPembayaran) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/$idPembayaran'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal memuat detail pembayaran');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> verifikasi({
    required int idPembayaran,
    required String statusVerifikasi,
    required String keterangan,
    required double jumlahPembayaran,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/verifikasi/$idPembayaran'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status_verifikasi': statusVerifikasi,
          'keterangan': keterangan,
          'jumlah_pembayaran': jumlahPembayaran,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memverifikasi pembayaran: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrlStorage}$path'; // Sesuaikan dengan base URL Anda
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Map<String, dynamic>>> getAllMetodePembayaran() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/metode-pembayaran'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat metode pembayaran');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> uploadBuktiPembayaran({
    required String metodePembayaranId,
    required File buktiPembayaran,
    required String jumlahPembayaran,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/upload'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['metode_pembayaran_id'] = metodePembayaranId;
      request.fields['jumlah_pembayaran'] = jumlahPembayaran;
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_pembayaran',
        buktiPembayaran.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal upload bukti pembayaran');
      }
    } catch (e) {
      print('upload error: $e');
      throw Exception('Gagal upload bukti pembayaran: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistoriPembayaran({required String year}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/histori?year=$year'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat histori pembayaran');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}