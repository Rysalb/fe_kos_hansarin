import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/admin/kelola_penyewa/ubah_penyewa.dart';
import 'package:proyekkos/screens/admin/kelola_kamar/pindah_kamar.dart';
import 'package:proyekkos/screens/admin/pembukuan/tambah_pemasukan_pengeluaran_screen.dart';

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
            onPressed: () async {
              // Navigate to TambahPemasukanPengeluaranScreen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TambahPemasukanPengeluaranScreen(
                    isPemasukan: true, // Set as pemasukan
                  ),
                ),
              );
              
              if (result == true) {
                _fetchData(); // Refresh data after adding payment
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B4B3E),
              minimumSize: Size(double.infinity, 45),
            ),
            child: Text('Perpanjang Sewa', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PindahKamarPage(
                    idPenyewa: widget.idPenyewa,
                    currentKamar: _penyewaDetail!['unit_kamar']['nomor_kamar'],
                  ),
                ),
              );
              if (result == true) {
                _fetchData(); // Refresh data setelah pindah kamar
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9F8C82),
              minimumSize: Size(double.infinity, 45),
            ),
            child: Text('Pindah Kamar', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showKeluarKosConfirmation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: Size(double.infinity, 45),
            ),
            child: Text('Keluar Kos', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showKeluarKosConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text(
            'Apakah Anda yakin ingin mengeluarkan penyewa "${_penyewaDetail!['user']['name']}" dari kos?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog
                await _keluarKos();
              },
              child: Text('Ya', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _keluarKos() async {
    try {
      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      await _penyewaService.deletePenyewa(widget.idPenyewa);

      // Tutup loading
      Navigator.of(context).pop();

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penyewa berhasil dikeluarkan dari kos'),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya
      Navigator.of(context).pop(true); // true untuk trigger refresh di halaman sebelumnya

    } catch (e) {
      // Tutup loading
      Navigator.of(context).pop();

      // Tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengeluarkan penyewa: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _calculateSisaHari(String tanggalKeluar) {
    final keluar = DateTime.parse(tanggalKeluar);
    final sekarang = DateTime.now();
    final selisih = keluar.difference(sekarang).inDays;
    return selisih < 0 ? 'Sewa telah berakhir' : selisih.toString();
  }
}