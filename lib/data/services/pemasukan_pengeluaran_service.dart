import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';
import 'dart:convert';

class PemasukanPengeluaranService {
  Future<void> create({
    required String jenisTransaksi,
    required String kategori,
    required DateTime tanggal,
    required double jumlah,
    required String keterangan,
    required int idPenyewa,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/create'),
        body: {
          'jenis_transaksi': jenisTransaksi,
          'kategori': kategori,
          'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
          'jumlah': jumlah.toString(),
          'keterangan': keterangan,
          'id_penyewa': idPenyewa.toString(),
        },
      );

      if (response.statusCode != 201) {
        throw Exception('Gagal menambah transaksi');
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
        return List<Map<String, dynamic>>.from(data['data']);
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
} 