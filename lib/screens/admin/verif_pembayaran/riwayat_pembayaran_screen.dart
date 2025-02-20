import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';

class RiwayatPembayaranScreen extends StatefulWidget {
  @override
  _RiwayatPembayaranScreenState createState() => _RiwayatPembayaranScreenState();
}

class _RiwayatPembayaranScreenState extends State<RiwayatPembayaranScreen> {
  final PembayaranService _service = PembayaranService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _riwayatList = [];
  String _selectedFilter = 'semua'; // semua, hari_ini, minggu_ini, bulan_ini

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();
      setState(() {
        _riwayatList = List<Map<String, dynamic>>.from(
          data.where((item) => _filterPembayaran(item))
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat pembayaran')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _filterPembayaran(Map<String, dynamic> pembayaran) {
    final tanggal = DateTime.parse(pembayaran['tanggal_pembayaran']);
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'hari_ini':
        return tanggal.year == now.year &&
               tanggal.month == now.month &&
               tanggal.day == now.day;
      case 'minggu_ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return tanggal.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
               tanggal.isBefore(endOfWeek.add(Duration(days: 1)));
      case 'bulan_ini':
        return tanggal.year == now.year && tanggal.month == now.month;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pembayaran'),
        backgroundColor: Color(0xFFE7B789),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter Waktu',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'semua', child: Text('Semua')),
                DropdownMenuItem(value: 'hari_ini', child: Text('Hari Ini')),
                DropdownMenuItem(value: 'minggu_ini', child: Text('Minggu Ini')),
                DropdownMenuItem(value: 'bulan_ini', child: Text('Bulan Ini')),
              ],
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                _loadRiwayat();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _riwayatList.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada riwayat pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _riwayatList.length,
                        itemBuilder: (context, index) {
                          final pembayaran = _riwayatList[index];
                          final penyewa = pembayaran['penyewa'];
                          
                          // Konversi jumlah ke double terlebih dahulu
                          double jumlah = double.parse(pembayaran['jumlah_pembayaran'].toString());
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            color: Color(0xFFFBE1CE),
                            child: ListTile(
                              leading: Image.asset(
                                'assets/images/avatar.png',
                                width: 50,
                                height: 50,
                              ),
                              title: Text('Kamar ${penyewa['unit_kamar']['nomor_kamar']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pembayaran['jenis_pembayaran'] ?? 'Bayar Sewa Kamar'),
                                  Text('Status: ${pembayaran['status_verifikasi']}'),
                                  Text(DateFormat('dd MMM yyyy').format(
                                    DateTime.parse(pembayaran['tanggal_pembayaran'])
                                  )),
                                ],
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(jumlah),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}