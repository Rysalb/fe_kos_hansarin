import 'dart:convert';
import 'package:http/http.dart' as http;
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
} 