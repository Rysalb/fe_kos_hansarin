import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/verifikasi/$idPembayaran'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status_verifikasi': statusVerifikasi,
          'keterangan': keterangan,
        }),
      );

      print('Verifikasi response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Gagal memverifikasi pembayaran: ${response.body}');
      }
    } catch (e) {
      print('Verifikasi error: $e');
      throw Exception('Error: $e');
    }
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrlStorage}$path'; // Sesuaikan dengan base URL Anda
  }
} 