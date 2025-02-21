import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/constants/api_constants.dart';

class KatalogMakananService {
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/katalog-makanan/get/all'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat data katalog makanan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> create({
    required String nama,
    required double harga,
    required String kategori,
    required String deskripsi,
    required File fotoMakanan,
    required String status,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/katalog-makanan/create'),
      );

      request.fields.addAll({
        'nama_makanan': nama,
        'harga': harga.toString(),
        'kategori': kategori,
        'deskripsi': deskripsi,
        'status': status,
      });

      request.files.add(await http.MultipartFile.fromPath(
        'foto_makanan',
        fotoMakanan.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      if (response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Gagal menambah katalog makanan: $responseBody');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> update({
    required int id,
    required String nama,
    required double harga,
    required String kategori,
    required String deskripsi,
    File? fotoMakanan,
    required String status,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/katalog-makanan/update/$id'),
      );

      request.fields.addAll({
        'nama_makanan': nama,
        'harga': harga.toString(),
        'kategori': kategori,
        'deskripsi': deskripsi,
        'status': status,
        '_method': 'PUT',
      });

      if (fotoMakanan != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto_makanan',
          fotoMakanan.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      var response = await request.send();
      var responseStr = await response.stream.bytesToString();
      
      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate menu: $responseStr');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/katalog-makanan/delete/$id'),
      );

      if (response.statusCode != 204) {
        throw Exception('Gagal menghapus katalog makanan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrlStorage}$path';
  }

  Future<List<Map<String, dynamic>>> getByKategori(String kategori) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/katalog-makanan/kategori/$kategori'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decode response body
        final responseData = json.decode(response.body);
        
        // Langsung return data tanpa mapping tambahan
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        throw Exception('Gagal memuat katalog makanan');
      }
    } catch (e) {
      print('Error in getByKategori: $e');
      throw Exception('Error: $e');
    }
  }
}