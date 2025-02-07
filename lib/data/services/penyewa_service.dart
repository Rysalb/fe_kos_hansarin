import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:proyekkos/core/constants/api_constants.dart';

class PenyewaService {
  Future<List<Map<String, dynamic>>> getAllPenyewa() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/all'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        throw Exception('Gagal mengambil data penyewa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getPenyewaById(int idPenyewa) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/$idPenyewa'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        throw Exception('Gagal mengambil detail penyewa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getAllUnits() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/unit-kamar/all'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        throw Exception('Failed to load unit data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updatePenyewa(int idPenyewa, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/update/$idPenyewa'),
        body: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui data penyewa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> updatePenyewaWithImage(
    int idPenyewa,
    Map<String, dynamic> data,
    File imageFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/penyewa/update/$idPenyewa'),
      );

      // Tambahkan fields
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Tambahkan file foto KTP
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'foto_ktp',
        stream,
        length,
        filename: 'foto_ktp.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      var response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui data penyewa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 