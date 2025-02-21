import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';

class PeraturanKosService {
  Future<List<Map<String, dynamic>>> getAllPeraturan() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/peraturan-kos/get/all'),
        headers: {'Accept': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        } else if (responseData['data'] != null) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
        return [];
      } else {
        throw Exception('Gagal memuat peraturan kos');
      }
    } catch (e) {
      print('Error in getAllPeraturan: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> createPeraturan(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/peraturan-kos/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updatePeraturan(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/peraturan-kos/update/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> deletePeraturan(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/peraturan-kos/delete/$id'),
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}