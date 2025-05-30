import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';

class NomorPentingService {
  Future<List<Map<String, dynamic>>> getAllNomorPenting() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/nomor-penting/get/all'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Print the response for debugging
        print('Response data: $responseData');
        
        if (responseData is List) {
          // If response is directly a list
          return List<Map<String, dynamic>>.from(responseData);
        } else if (responseData['data'] != null) {
          // If response has a data field
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
        return [];
      } else {
        throw Exception('Gagal memuat nomor penting: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllNomorPenting: $e');
      throw Exception('Error: $e');
    }
  }

  Future<bool> createNomorPenting(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/nomor-penting/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> updateNomorPenting(int id, Map<String, dynamic> data) async {
    try {
      print('Update URL: ${ApiConstants.baseUrl}/nomor-penting/update/$id'); // Debug URL
      print('Request body: ${json.encode(data)}'); // Debug request body
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/nomor-penting/update/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Tambahkan header Accept
        },
        body: json.encode(data),
      );

      print('Response status: ${response.statusCode}'); // Debug response status
      print('Response body: ${response.body}'); // Debug response body

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating nomor penting: $e'); // Debug error
      throw Exception('Error: $e');
    }
  }

  Future<bool> deleteNomorPenting(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/nomor-penting/delete/$id'),
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}