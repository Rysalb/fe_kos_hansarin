import 'package:flutter/material.dart';
import 'dart:io';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'package:proyekkos/data/services/notification_service.dart'; // Tambahkan ini
import 'package:proyekkos/screens/users/order_menu/order_success_page.dart';

class UploadBuktiScreen extends StatefulWidget {
  final File buktiPembayaran;
  final String idMetode;
  final double totalPembayaran;
  final List<Map<String, dynamic>> pesanan; 
  final int idPenyewa;

  const UploadBuktiScreen({
    Key? key,
    required this.buktiPembayaran,
    required this.idMetode,
    required this.totalPembayaran,
    required this.pesanan, 
    required this.idPenyewa,
  }) : super(key: key);

  @override
  _UploadBuktiScreenState createState() => _UploadBuktiScreenState();
}

class _UploadBuktiScreenState extends State<UploadBuktiScreen> {
  bool _isUploading = false;
  final PembayaranService _pembayaranService = PembayaranService();
  final NotificationService _notificationService = NotificationService(); // Tambahkan ini

  // Metode untuk mengirim notifikasi ke admin
  Future<void> _sendNotificationToAdmin(String totalPembayaran) async {
    try {
      // Hitung jumlah item makanan
      int totalItems = 0;
      for (var item in widget.pesanan) {
        totalItems += int.parse(item['jumlah'].toString());
      }
      
      await _notificationService.sendNotificationToAdmins(
        title: 'Pesanan Menu Baru',
        message: 'Pesanan menu baru dengan $totalItems item menunggu verifikasi',
        type: 'payment_verification',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'amount': totalPembayaran,
          'is_order_menu': true,
        },
      );
      print('Notifikasi berhasil dikirim ke admin');
    } catch (e) {
      print('Gagal mengirim notifikasi ke admin: $e');
    }
  }

  Future<void> _uploadBukti() async {
    setState(() => _isUploading = true);
    try {
      // Upload bukti pembayaran with "Order Menu" keterangan
      final response = await _pembayaranService.uploadBuktiPembayaranOrder(
        metodePembayaranId: widget.idMetode,
        buktiPembayaran: widget.buktiPembayaran,
        jumlahPembayaran: widget.totalPembayaran.toString(),
        keterangan: 'Order Menu', 
        pesanan: widget.pesanan,
        idPenyewa: widget.idPenyewa,
      );

      // Kirim notifikasi ke admin setelah upload berhasil
      await _sendNotificationToAdmin(widget.totalPembayaran.toString());

      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSuccessPage(),
        ),
      );
    } catch (e) {
      print('Error uploading: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah bukti pembayaran: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE7B789),
        title: Text(
          'Upload Bukti Pembayaran',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview bukti pembayaran
            Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.buktiPembayaran,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 24),
            // Total pembayaran
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFE5CC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total Pembayaran: Rp ${widget.totalPembayaran.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            // Tombol konfirmasi
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadBukti,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A2F1C),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}