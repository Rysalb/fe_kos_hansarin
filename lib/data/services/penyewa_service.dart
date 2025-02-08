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

  Future<Map<String, dynamic>> createPenyewa({
    required String name,
    required String email,
    required String password,
    required String idUnit,
    required String nik,
    required File fotoKtp,
    required String alamatAsal,
    required String nomorWa,
    required String tanggalMasuk,
    required int durasiSewa,
    required double hargaSewa,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/penyewa/create'),
      );

      // Add text fields
      request.fields.addAll({
        'name': name,
        'email': email,
        'password': password,
        'id_unit': idUnit,
        'nik': nik,
        'alamat_asal': alamatAsal,
        'nomor_wa': nomorWa,
        'tanggal_masuk': tanggalMasuk,
        'durasi_sewa': durasiSewa.toString(),
        'harga_sewa': hargaSewa.toString(),
        'status_verifikasi': 'disetujui',
      });

      // Add KTP file
      var ktpStream = http.ByteStream(fotoKtp.openRead());
      var length = await fotoKtp.length();
      var multipartFile = http.MultipartFile(
        'foto_ktp',
        ktpStream,
        length,
        filename: 'foto_ktp.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      print('Sending request to: ${request.url}'); // Debug
      print('Request fields: ${request.fields}'); // Debug

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode != 200) {
        Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menambahkan penyewa');
      }

      return json.decode(response.body); // Return response data
    } catch (e) {
      print('Error in createPenyewa: $e'); // Debug
      throw Exception('Error creating penyewa: $e');
    }
  }

  Future<Map<String, dynamic>> getKamarDetail(String idUnit) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/unit-kamar/detail/$idUnit'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return responseData['data'];
        } else {
          throw Exception('Data kamar tidak ditemukan');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load kamar detail');
      }
    } catch (e) {
      print('Error getting kamar detail: $e'); // Debug
      throw Exception('Error getting kamar detail: $e');
    }
  }

  Future<List<dynamic>> getUnitTersedia(String idKamar) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/unit-tersedia/$idKamar'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return List<dynamic>.from(responseData['data']);
      } else {
        throw Exception('Gagal mendapatkan unit tersedia');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> pindahKamar(int idPenyewa, int idUnitBaru) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/pindah-kamar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_penyewa': idPenyewa,
          'id_unit_baru': idUnitBaru,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal pindah kamar');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deletePenyewa(int idPenyewa) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/penyewa/delete/$idPenyewa'),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menghapus penyewa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 