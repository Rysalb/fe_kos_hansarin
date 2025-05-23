import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'package:proyekkos/screens/admin/verif_pembayaran/riwayat_pembayaran_screen.dart';
import 'dart:io';
import 'package:proyekkos/data/services/notification_service.dart';

class VerifikasiPembayaranScreen extends StatefulWidget {
  @override
  _VerifikasiPembayaranScreenState createState() => _VerifikasiPembayaranScreenState();
}

class _VerifikasiPembayaranScreenState extends State<VerifikasiPembayaranScreen> {
  final PembayaranService _service = PembayaranService();
  final NotificationService _notificationService = NotificationService();
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
        _pembayaranList = data.where((item) {
          // Add null checks for nested properties
          final statusVerifikasi = item['status_verifikasi'];
          final penyewa = item['penyewa'];
          final user = penyewa?['user'];
          final unitKamar = penyewa?['unit_kamar'];
          final metodePembayaran = item['metode_pembayaran'];

          // Check if required data exists
          if (statusVerifikasi == null || 
              penyewa == null || 
              user == null || 
              unitKamar == null || 
              metodePembayaran == null) {
            print('Missing required data for item: $item');
            return false;
          }

          return statusVerifikasi == 'pending';
        }).toList();
      });
    } catch (e) {
      print('Error loading payments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data pembayaran: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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

    // Fix number parsing
    double jumlah = 0.0;
    try {
      if (pembayaran['jumlah_pembayaran'] != null) {
        if (pembayaran['jumlah_pembayaran'] is num) {
          jumlah = (pembayaran['jumlah_pembayaran'] as num).toDouble();
        } else {
          jumlah = double.tryParse(pembayaran['jumlah_pembayaran'].toString()) ?? 0.0;
        }
      }
    } catch (e) {
      print('Error parsing jumlah_pembayaran: $e');
    }

    String imageUrl = _service.getImageUrl(pembayaran['bukti_pembayaran']);
    bool isOrderMenu = pembayaran['keterangan'] == 'Order Menu';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
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
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    formatter.format(jumlah),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
                _buildDetailRow('Kategori', isOrderMenu ? 'Order Menu' : 'Bayar Sewa Kamar'),
                _buildDetailRow('No Pesanan', pembayaran['id_pembayaran']?.toString()?.padLeft(6, '0') ?? 'N/A'),
                _buildDetailRow('Via Pembayaran', pembayaran['metode_pembayaran']?['nama'] ?? 'Tidak diketahui'),
                _buildDetailRow('Tanggal Bayar', DateFormat('dd MMMM yyyy').format(DateTime.parse(pembayaran['tanggal_pembayaran']))),
                if (!isOrderMenu) ...[
                  _buildDetailRow('Kamar', penyewa['unit_kamar']['nomor_kamar']),
                  _buildDetailRow('Periode', '${penyewa['tanggal_masuk']} - ${penyewa['tanggal_keluar']}'),
                ],
                if (isOrderMenu && pembayaran['pesanan_makanan'] != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Detail Pesanan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...pembayaran['pesanan_makanan'].map<Widget>((pesanan) {
                    double totalHarga = 0.0;
                    try {
                      if (pesanan['total_harga'] != null) {
                        if (pesanan['total_harga'] is num) {
                          totalHarga = (pesanan['total_harga'] as num).toDouble();
                        } else {
                          totalHarga = double.tryParse(pesanan['total_harga'].toString()) ?? 0.0;
                        }
                      }
                    } catch (e) {
                      print('Error parsing total_harga: $e');
                    }
                    
                    return Text(
                      '${pesanan['jumlah']}x ${pesanan['katalog_makanan']['nama_makanan']} ' +
                      '(${formatter.format(totalHarga)})'
                    );
                  }).toList(),
                ],
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
        String originalKeterangan = pembayaran['keterangan'] ?? '';
        
        // Check if this is a rent payment
        final bool isRentPayment = !originalKeterangan.contains('Order Menu');
        
        if (isRentPayment) {
          // Extract duration from keterangan
          RegExp durasiRegex = RegExp(r'(\d+) Bulan');
          final match = durasiRegex.firstMatch(originalKeterangan);
          int durasiSewa = 1; // Default to 1 month
          
          if (match != null && match.groupCount > 0) {
            durasiSewa = int.tryParse(match.group(1) ?? '1') ?? 1;
          }

          // Calculate new checkout date
          final currentCheckoutDate = DateTime.parse(pembayaran['penyewa']['tanggal_keluar']);
          final newCheckoutDate = currentCheckoutDate.add(Duration(days: 30 * durasiSewa));

          // Verify payment and update checkout date
          await _service.verifikasi(
            idPembayaran: pembayaran['id_pembayaran'],
            statusVerifikasi: 'verified', 
            keterangan: originalKeterangan,
            jumlahPembayaran: jumlahPembayaran,
            idPenyewa: pembayaran['penyewa']['id_penyewa'],
            durasi: durasiSewa,
            tanggalKeluar: newCheckoutDate.toIso8601String(),
          );
        } else {
          await _service.verifikasi(
            idPembayaran: pembayaran['id_pembayaran'],
            statusVerifikasi: 'verified',
            keterangan: originalKeterangan,
            jumlahPembayaran: jumlahPembayaran,
          );
        }

        // Send notification
        await _notificationService.sendNotificationToSpecificUser(
          userId: pembayaran['penyewa']['user']['id_user'].toString(),
          title: 'Pembayaran Diverifikasi',
          message: 'Pembayaran untuk ${pembayaran['keterangan'] == 'Order Menu' ? 'pesanan makanan' : 'sewa kamar'} Anda telah diverifikasi',
          type: 'payment_verification',
          data: {
            'id_pembayaran': pembayaran['id_pembayaran'],
          },
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

  Future<void> _showTolakConfirmation(Map<String, dynamic> pembayaran) async {
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
          idPembayaran: pembayaran['id_pembayaran'],
          statusVerifikasi: 'rejected',
          keterangan: result,
        );
        
        // Send notification to the user about the rejected payment
        await _notificationService.sendNotificationToSpecificUser(
          userId: pembayaran['penyewa']['user']['id_user'].toString(),
          title: 'Pembayaran Ditolak',
          message: 'Pembayaran untuk ${pembayaran['keterangan'] == 'Order Menu' ? 'pesanan makanan' : 'sewa kamar'} Anda ditolak: $result',
          type: 'payment_rejected', // Use a distinct type for rejected payments
          data: {
            'id_pembayaran': pembayaran['id_pembayaran'],
            'rejection_reason': result,
          },
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

  Widget _buildPembayaranItem(Map<String, dynamic> pembayaran) {
    final bool isOrderMenu = pembayaran['keterangan'] == 'Order Menu';
    final penyewa = pembayaran['penyewa'];
    final user = penyewa?['user'];
    final unitKamar = penyewa?['unit_kamar'];
    final metodePembayaran = pembayaran['metode_pembayaran'];
    
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
                  isOrderMenu ? 'assets/images/pesanmakan.png' : 'assets/images/avatar.png',
                  width: 60,
                  height: 60,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOrderMenu ? 'Order Menu' : 'Kamar ${unitKamar?['nomor_kamar'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(isOrderMenu ? 'Pembayaran Makanan/Minuman' : 'Pembayaran Sewa Kamar'),
                      SizedBox(height: 8),
                      Text('Nama: ${user?['name'] ?? 'N/A'}'),
                      Text('No HP: ${penyewa?['nomor_wa'] ?? 'N/A'}'),
                      Text('Pembayaran Melalui: ${metodePembayaran?['nama'] ?? 'N/A'}'),
                      Text('Total: Rp ${pembayaran['jumlah_pembayaran'] ?? '0'}'),
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
                  onPressed: () => _showTolakConfirmation(pembayaran), // Pass the entire pembayaran object
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
                  onPressed: () => _showVerifikasiConfirmation(pembayaran),
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
                    return _buildPembayaranItem(pembayaran);
                  },
                ),
    );
  }
}