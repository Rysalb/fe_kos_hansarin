import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

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
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          // Convert the data to List<Map<String, dynamic>>
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
        return [];
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
    required double jumlahPembayaran,
    int? idPenyewa,
    int? durasi,
    String? tanggalKeluar,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final Map<String, dynamic> body = {
        'status_verifikasi': statusVerifikasi,
        'keterangan': keterangan,
        'jumlah_pembayaran': jumlahPembayaran,
      };

      // Add penyewa data if provided
      if (idPenyewa != null) {
        body['id_penyewa'] = idPenyewa;
      }
      
      // Add durasi & tanggal_keluar for rent payments
      if (durasi != null) {
        body['durasi'] = durasi;
      }
      if (tanggalKeluar != null) {
        body['tanggal_keluar'] = tanggalKeluar;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/verifikasi/$idPembayaran'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memverifikasi pembayaran: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '${ApiConstants.baseUrlStorage}/storage/$path'; // Sesuaikan dengan base URL Anda
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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

  Future<void> uploadBuktiPembayaran({
  required String metodePembayaranId,
  required File buktiPembayaran,
  required String jumlahPembayaran,
  required String keterangan,
}) async {
  try {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/pembayaran/upload'),
    )
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      })
      ..fields.addAll({
        'metode_pembayaran_id': metodePembayaranId, // Make sure this matches the backend field name
        'jumlah_pembayaran': jumlahPembayaran,
        'keterangan': keterangan,
      })
      ..files.add(await http.MultipartFile.fromPath(
        'bukti_pembayaran',
        buktiPembayaran.path,
      ));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    print('upload response: $responseData');

    if (response.statusCode != 200) {
      throw Exception('Gagal upload bukti pembayaran: ${json.decode(responseData)['message']}');
    }
  } catch (e) {
    print('upload error: $e');
    throw Exception('Gagal upload bukti pembayaran: $e');
  }
}

Future<Map<String, dynamic>> uploadBuktiPembayaranOrder({
  required String metodePembayaranId,
  required File buktiPembayaran,
  required String jumlahPembayaran,
  required String keterangan,
  required List<Map<String, dynamic>> pesanan,
  required int idPenyewa,
}) async {
  try {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    // First create payment record
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/pembayaran/upload'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields.addAll({
      'metode_pembayaran_id': metodePembayaranId,
      'jumlah_pembayaran': jumlahPembayaran,
      'keterangan': keterangan,
      'id_penyewa': idPenyewa.toString(),
    });

    request.files.add(await http.MultipartFile.fromPath(
      'bukti_pembayaran',
      buktiPembayaran.path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Payment Response: ${response.statusCode}');
    print('Payment Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to upload payment proof');
    }

    final responseData = json.decode(response.body);
    final idPembayaran = responseData['data']['id_pembayaran'];

    // Then create food order
    final orderResponse = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/pesanan-makanan/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_penyewa': idPenyewa,
        'id_pembayaran': idPembayaran,
        'pesanan': pesanan,
        'total_harga': double.parse(jumlahPembayaran), // Add this field
      }),
    );

    print('Order Response: ${orderResponse.statusCode}');
    print('Order Body: ${orderResponse.body}');

    if (orderResponse.statusCode != 201) {
      throw Exception('Failed to create order');
    }

    return responseData;
  } catch (e) {
    print('Upload error: $e');
    throw Exception('Error: $e');
  }
}

  Future<List<Map<String, dynamic>>> getHistoriPembayaran({required String year}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pembayaran/histori?year=$year'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat histori pembayaran');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

 Future<Map<String, dynamic>> getUserKamarDetail() async {
  try {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    // Update endpoint to match the route in api.php
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/penyewa/kamar-detail'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Kamar detail response: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == true && responseData['data'] != null) {
        return responseData['data'];
      }
      throw Exception(responseData['message'] ?? 'Gagal memuat detail kamar');
    } else if (response.statusCode == 404) {
      throw Exception('Data kamar tidak ditemukan');
    } else {
      throw Exception('Gagal memuat detail kamar: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getUserKamarDetail: $e');
    throw Exception('Gagal memuat detail kamar: $e');
  }
}
}