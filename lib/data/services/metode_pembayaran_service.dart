import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';

class MetodePembayaranService {
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

  Future<void> addMetodePembayaran(Map<String, dynamic> data) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/metode-pembayaran/create'),
      );

      // Add text fields
      request.fields['kategori'] = data['kategori'];
      request.fields['nama'] = data['nama'];
      if (data['nomor_rekening'] != null) {
        request.fields['nomor_rekening'] = data['nomor_rekening'];
      }

      // Add files
      if (data['logo'] != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'logo',
          data['logo'].path,
        ));
      }

      if (data['qr_code'] != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'qr_code',
          data['qr_code'].path,
        ));
      }

      final response = await request.send();
      
      if (response.statusCode != 200) {
        throw Exception('Failed to add metode pembayaran');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> deleteMetodePembayaran(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/metode-pembayaran/delete/$id'),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateMetodePembayaran(int id, Map<String, dynamic> data) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/metode-pembayaran/update/$id'),
      );

      // Add text fields
      request.fields['kategori'] = data['kategori'];
      request.fields['nama'] = data['nama'];
      if (data['nomor_rekening'] != null) {
        request.fields['nomor_rekening'] = data['nomor_rekening'];
      }

      // Add files if they exist
      if (data['logo'] != null && data['logo'] is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'logo',
          data['logo'].path,
        ));
      }

      if (data['qr_code'] != null && data['qr_code'] is File) {
        request.files.add(await http.MultipartFile.fromPath(
          'qr_code',
          data['qr_code'].path,
        ));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

Future<Map<String, dynamic>> getMetodePembayaranById(int id) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/metode-pembayaran/$id'),
      headers: {'Accept': 'application/json'},
    );

    print('Response status: ${response.statusCode}'); // Debug print
    print('Response body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final data = responseData['data'];
      
      // Transform the URLs to include base URL
      if (data['logo'] != null) {
        data['logo'] = data['logo'].startsWith('http') 
          ? data['logo'] 
          : '${ApiConstants.baseUrlStorage}/storage/${data['logo']}';
      }
      if (data['qr_code'] != null) {
        data['qr_code'] = data['qr_code'].startsWith('http') 
          ? data['qr_code'] 
          : '${ApiConstants.baseUrlStorage}/storage/${data['qr_code']}';
      }
      
      return data;
    } else {
      throw Exception('Failed to load metode pembayaran');
    }
  } catch (e) {
    print('Error detail: $e'); // Debug print
    throw Exception('Error: $e');
  }
}

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${path}';
  }
} 