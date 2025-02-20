import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:proyekkos/screens/users/pembayaran/upload_bukti_bayar_screen.dart';

class BayarSewaScreen extends StatefulWidget {
  @override
  _BayarSewaScreenState createState() => _BayarSewaScreenState();
}

class _BayarSewaScreenState extends State<BayarSewaScreen> {
  final MetodePembayaranService _service = MetodePembayaranService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _metodePembayaran = [];

  @override
  void initState() {
    super.initState();
    _loadMetodePembayaran();
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final data = await _service.getAllMetodePembayaran();
      setState(() {
        _metodePembayaran = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat metode pembayaran')),
      );
    }
  }

  Future<void> _saveQRToGallery(String qrUrl) async {
    try {
      final response = await http.get(Uri.parse(qrUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code.png');
      await file.writeAsBytes(response.bodyBytes);
      
      await GallerySaver.saveImage(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR Code berhasil disimpan ke galeri')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan QR Code')),
      );
    }
  }

  void _showPaymentDetails(Map<String, dynamic> metode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metode['nama'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              if (metode['kategori'] == 'bank') ...[
                Text('Nomor Rekening:'),
                SelectableText(
                  metode['nomor_rekening'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (metode['kategori'] == 'e-wallet' && metode['qr_code'] != null) ...[
                Image.network(
                  metode['qr_code'],
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _saveQRToGallery(metode['qr_code']),
                  child: Text('Simpan QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A2F1C),
                  ),
                ),
              ],
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bayar Sewa Kos'),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _metodePembayaran.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada metode pembayaran yang tersedia',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ..._metodePembayaran.map((metode) => Card(
                        color: Color.fromRGBO(243,212,180, 2),
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () => _showPaymentDetails(metode),
                          leading: Image.network(
                            metode['logo'],
                            width: 50,
                            height: 50,
                          ),
                          title: Text(metode['nama']),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      )).toList(),
                      SizedBox(height: 50),
                      Center(
                        child: Text(
                          'Silahkan kirim bukti pembayaran pada\ntombol dibawah ini',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UploadBuktiBayarScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A2F1C),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Upload Bukti Bayar Sewa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 