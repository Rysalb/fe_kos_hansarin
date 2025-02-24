import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'package:proyekkos/screens/admin/verif_pembayaran/riwayat_pembayaran_screen.dart';
import 'dart:io';

class VerifikasiPembayaranScreen extends StatefulWidget {
  @override
  _VerifikasiPembayaranScreenState createState() => _VerifikasiPembayaranScreenState();
}

class _VerifikasiPembayaranScreenState extends State<VerifikasiPembayaranScreen> {
  final PembayaranService _service = PembayaranService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pembayaranList = [];

  @override
  void initState() {
    super.initState();
    _loadPembayaran();
  }

  Future<void> _loadPembayaran() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();
      setState(() {
        _pembayaranList = List<Map<String, dynamic>>.from(
          data.where((item) => item['status_verifikasi'] == 'pending')
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data pembayaran')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifikasiPembayaran(int idPembayaran, bool isVerified) async {
    try {
      await _service.verifikasi(
        jumlahPembayaran: 0.0,
        idPembayaran: idPembayaran,
        statusVerifikasi: isVerified ? 'verified' : 'rejected',
        keterangan: isVerified ? 'Pembayaran diverifikasi' : 'Pembayaran ditolak',
      );
      await _loadPembayaran();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pembayaran berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status pembayaran')),
      );
    }
  }

  Future<void> _showDetailPembayaran(Map<String, dynamic> pembayaran) async {
    final penyewa = pembayaran['penyewa'];
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    double jumlah = double.tryParse(pembayaran['jumlah_pembayaran'].toString()) ?? 0.0;

    String imageUrl = _service.getImageUrl(pembayaran['bukti_pembayaran']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showFullImage(imageUrl),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {
                        print('Error loading image');
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  formatter.format(jumlah),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow('Kategori', pembayaran['jenis_pembayaran'] ?? 'Bayar Sewa Kamar'),
              _buildDetailRow('No Pesanan', pembayaran['id_pembayaran']?.toString()?.padLeft(6, '0') ?? 'N/A'),
              _buildDetailRow(
                'Via Pembayaran', 
                pembayaran['metode_pembayaran']?['nama'] ?? 'Tidak diketahui'
              ),
              _buildDetailRow('Tanggal Bayar', 
                DateFormat('dd MMMM yyyy').format(DateTime.parse(pembayaran['tanggal_pembayaran'] ?? DateTime.now().toString()))
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Kembali'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE7B789),
                    minimumSize: Size(double.infinity, 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading full image: $error');
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    Text('Gagal memuat gambar'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showVerifikasiConfirmation(Map<String, dynamic> pembayaran) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Verifikasi'),
        content: Text('Pastikan uang telah masuk. Lanjutkan verifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('Verifikasi'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        double jumlahPembayaran = double.parse(pembayaran['jumlah_pembayaran'].toString());
        
        await _service.verifikasi(
          idPembayaran: pembayaran['id_pembayaran'],
          statusVerifikasi: 'verified',
          keterangan: 'Pembayaran diverifikasi',
          jumlahPembayaran: jumlahPembayaran,
        );
        
        await _loadPembayaran();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran berhasil diverifikasi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memverifikasi pembayaran')),
        );
      }
    }
  }

  Future<void> _showTolakConfirmation(int idPembayaran) async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan alasan penolakan',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alasan penolakan harus diisi')),
                );
                return;
              }
              Navigator.pop(context, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Tolak'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _service.verifikasi(
          jumlahPembayaran: 0.0,
          idPembayaran: idPembayaran,
          statusVerifikasi: 'rejected',
          keterangan: result,
        );
        await _loadPembayaran();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pembayaran berhasil ditolak')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak pembayaran')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifikasi Laporan Pembayaran',style: TextStyle(fontSize: 18),),
        backgroundColor: Color(0xFFE7B789),
        actions: [
          IconButton(
            icon: Image.asset('assets/images/dashboard_icon/verifikasi_pembayaran.png'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiwayatPembayaranScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pembayaranList.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada data pembayaran yang perlu diverifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _pembayaranList.length,
                  itemBuilder: (context, index) {
                    final pembayaran = _pembayaranList[index];
                    final penyewa = pembayaran['penyewa'];
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      color: Color(0xFFFBE1CE),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/avatar.png',
                                  width: 60,
                                  height: 60,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kamar ${penyewa['unit_kamar']['nomor_kamar']}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(pembayaran['jenis_pembayaran'] ?? 'Bayar Sewa Kamar'),
                                      SizedBox(height: 8),
                                      Text('Nama: ${penyewa['user']['name']}'),
                                      Text('Asal: ${penyewa['alamat_asal']}'),
                                      Text('Tanggal Masuk: ${DateFormat('dd MMM yyyy').format(DateTime.parse(penyewa['tanggal_masuk']))}'),
                                      Text('Tanggal Keluar: ${DateFormat('dd MMM yyyy').format(DateTime.parse(penyewa['tanggal_keluar']))}'),
                                      Text('No HP: ${penyewa['nomor_wa']}'),
                                      Text('Pembayaran Melalui: ${pembayaran['metode_pembayaran']['nama']}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _showTolakConfirmation(pembayaran['id_pembayaran']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  child: Text('Tolak'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showDetailPembayaran(pembayaran),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4A2F1C),
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  child: Text('Detail'),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showVerifikasiConfirmation(pembayaran), // Pass the whole pembayaran object
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  child: Text('Verifikasi'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}