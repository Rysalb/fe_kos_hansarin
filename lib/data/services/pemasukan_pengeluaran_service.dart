import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:proyekkos/core/constants/api_constants.dart';

class PemasukanPengeluaranService {
  Future<void> create(
    String jenisTransaksi,
    String kategori,
    DateTime tanggal,
    double jumlah,
    String keterangan,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pemasukan-pengeluaran/create'),
        body: {
          'jenis_transaksi': jenisTransaksi,
          'kategori': kategori,
          'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
          'jumlah': jumlah.toString(),
          'keterangan': keterangan,
        },
      );

      if (response.statusCode != 201) {
        throw Exception('Gagal menambah transaksi');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 