import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/admin/ubah_penyewa.dart';

class DetailPenyewaPage extends StatefulWidget {
  final int idPenyewa;

  DetailPenyewaPage({required this.idPenyewa});

  @override
  _DetailPenyewaPageState createState() => _DetailPenyewaPageState();
}

class _DetailPenyewaPageState extends State<DetailPenyewaPage> {
  final PenyewaService _penyewaService = PenyewaService();
  final PemasukanPengeluaranService _transaksiService = PemasukanPengeluaranService();
  Map<String, dynamic>? _penyewaDetail;
  List<Map<String, dynamic>> _riwayatTransaksi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final detail = await _penyewaService.getPenyewaById(widget.idPenyewa);
      final transaksi = await _transaksiService.getRiwayatTransaksiPenyewa(widget.idPenyewa);
      setState(() {
        _penyewaDetail = detail;
        _riwayatTransaksi = transaksi;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text('Detail Penyewa', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UbahPenyewaPage(
                      idPenyewa: widget.idPenyewa,
                    ),
                  ),
                );
                if (result == true) {
                  _fetchData(); // Refresh data setelah update
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B4B3E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Ubah Penyewa',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildInfoSection(),
                  _buildTransactionHistory(),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection() {
    if (_penyewaDetail == null) return SizedBox();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFE5CC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Icon(Icons.person, color: Colors.grey),
                radius: 30,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _penyewaDetail!['unit_kamar']['nomor_kamar'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Nama: ${_penyewaDetail!['user']['name']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Sisa: ${_calculateSisaHari(_penyewaDetail!['tanggal_keluar'])} hari',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _penyewaDetail!['status_penyewa'] == 'aktif'
                      ? Colors.green
                      : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _penyewaDetail!['status_penyewa'],
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          _riwayatTransaksi.isEmpty
              ? Center(
                  child: Text('Belum ada riwayat transaksi'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _riwayatTransaksi.length,
                  itemBuilder: (context, index) {
                    final transaksi = _riwayatTransaksi[index];
                    final jumlah = double.parse(transaksi['jumlah'].toString());
                    
                    return Card(
                      child: ListTile(
                        title: Text(
                          'Pembayaran Sewa',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(transaksi['tanggal']))}'),
                            Text('Jumlah: Rp ${NumberFormat('#,###').format(jumlah)}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Implementasi untuk perpanjang sewa
            },
            child: Text('Perpanjang Sewa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B4B3E),
              minimumSize: Size(double.infinity, 45),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Implementasi untuk pindah kamar
            },
            child: Text('Pindah Kamar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9F8C82),
              minimumSize: Size(double.infinity, 45),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Implementasi untuk keluar kos
            },
            child: Text('Keluar Kos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateSisaHari(String tanggalKeluar) {
    final keluar = DateTime.parse(tanggalKeluar);
    final sekarang = DateTime.now();
    final selisih = keluar.difference(sekarang).inDays;
    return selisih < 0 ? 'Sewa telah berakhir' : selisih.toString();
  }
} 