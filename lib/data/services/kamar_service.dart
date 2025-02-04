import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_constants.dart';

class KamarService {
  Future<List<dynamic>?> getAllKamar() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/kamarall'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error in getAllKamar: $e');
      return null;
    }
  }

  Future<bool> createKamar(Map<String, dynamic> kamarData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/kamar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(kamarData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error in createKamar: $e');
      return false;
    }
  }

  Future<bool> updateKamar(int idKamar, Map<String, dynamic> kamarData) async {
    try {
      print('Updating kamar with ID: $idKamar');
      print('Request data: ${json.encode(kamarData)}');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/kamarupdate/$idKamar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(kamarData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['message'] != null;
      }
      return false;
    } catch (e) {
      print('Error in updateKamar: $e');
      return false;
    }
  }

  Future<bool> deleteKamar(int idKamar) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/kamardel/$idKamar'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteKamar: $e');
      return false;
    }
  }
} 