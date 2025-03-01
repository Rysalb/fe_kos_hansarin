import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';
import 'dart:convert';

class PemasukanPengeluaranService {
Future<Map<String, dynamic>> create({
  required String jenisTransaksi,
  required String kategori,
  required DateTime tanggal,
  required double jumlah,
  required String keterangan,
  int? idPenyewa,
  String? metodePembayaran,
  int? idUser,
  int? durasi,              // Add durasi parameter
  String? tanggalKeluar,    // Add tanggalKeluar parameter
}) async {
  try {
    final Map<String, dynamic> body = {
      'jenis_transaksi': jenisTransaksi,
      'kategori': kategori,
      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
      'jumlah': jumlah,
      'keterangan': keterangan,
    };

    if (idPenyewa != null) {
      body['id_penyewa'] = idPenyewa;
    }

    if (idUser != null) {
      body['id_user'] = idUser;
    }

    if (metodePembayaran != null) {
      body['metode_pembayaran'] = metodePembayaran;
      body['id_metode'] = metodePembayaran == 'Dibayar' ? 1 : null;
    }

    // Add durasi and tanggalKeluar if provided
    if (durasi != null) {
      body['durasi'] = durasi;
    }

    if (tanggalKeluar != null) {
      body['tanggal_keluar'] = tanggalKeluar;
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/create'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal membuat transaksi: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}

  Future<List<Map<String, dynamic>>> getRiwayatTransaksiPenyewa(int idPenyewa) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/penyewa/$idPenyewa'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Gagal memuat riwayat transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getRekapBulanan(int bulan, int tahun) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/rekap-bulanan/$bulan/$tahun'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Gagal memuat rekap bulanan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransaksi() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/get/all'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data'].map((item) {
            // Ensure proper type casting
            Map<String, dynamic> mappedItem = Map<String, dynamic>.from(item);
            
            // Handle nested objects
            if (item['penyewa'] != null) {
              mappedItem['penyewa'] = Map<String, dynamic>.from(item['penyewa']);
              if (item['penyewa']['user'] != null) {
                mappedItem['penyewa']['user'] = Map<String, dynamic>.from(item['penyewa']['user']);
              }
              if (item['penyewa']['unit_kamar'] != null) {
                mappedItem['penyewa']['unit_kamar'] = Map<String, dynamic>.from(item['penyewa']['unit_kamar']);
              }
            }
            
            if (item['metode_pembayaran'] != null) {
              mappedItem['metode_pembayaran'] = Map<String, dynamic>.from(item['metode_pembayaran']);
            }
            
            return mappedItem;
          }));
        }
        return [];
      } else {
        throw Exception('Gagal memuat transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getTransaksiByDate(DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/by-date/${DateFormat('yyyy-MM-dd').format(date)}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Gagal memuat data transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTransaksiByJenis(String jenis) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/by-jenis/$jenis'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Gagal memuat data transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> update({
    required int id,
    required String jenisTransaksi,
    required String kategori,
    required DateTime tanggal,
    required double jumlah,
    required String keterangan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/update/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jenis_transaksi': jenisTransaksi,
          'kategori': kategori,
          'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
          'jumlah': jumlah,
          'keterangan': keterangan,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Gagal memperbarui transaksi: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/delete/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}