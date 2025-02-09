import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';

class PeraturanKosService {
  Future<List<Map<String, dynamic>>> getAllPeraturan() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/peraturan-kos'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load peraturan kos');
      }
    } catch (e) {
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