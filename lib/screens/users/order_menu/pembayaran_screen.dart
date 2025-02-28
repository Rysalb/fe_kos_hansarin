import 'package:flutter/material.dart';
import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import 'package:proyekkos/screens/users/order_menu/upload_bukti_screen.dart';

class PembayaranScreen extends StatefulWidget {
  final String idMetode;
  final double totalPembayaran;
  final List<Map<String, dynamic>> pesanan; // Add this

  const PembayaranScreen({
    Key? key,
    required this.idMetode,
    required this.totalPembayaran,
    required this.pesanan, // Add this
  }) : super(key: key);

  @override
  _PembayaranScreenState createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final MetodePembayaranService _metodePembayaranService = MetodePembayaranService();
  bool _isLoading = true;
  Map<String, dynamic>? _metodePembayaran;
  File? _buktiPembayaran;
  final ImagePicker _picker = ImagePicker();
  static const platform = MethodChannel('com.example.app/scanfile');

  @override
  void initState() {
    super.initState();
    _loadMetodePembayaran();
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final data = await _metodePembayaranService.getMetodePembayaranById(int.parse(widget.idMetode));
      setState(() {
        _metodePembayaran = data; // Remove ['data'] since it's already handled in service
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat detail pembayaran')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _buktiPembayaran = File(image.path);
        });
        
        // Get user ID from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('id_penyewa');
        
        print('Retrieved penyewa ID: $userId'); // Debug print

        if (userId == null) {
          // Show a more helpful error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesi anda telah berakhir. Silakan login kembali.'),
              backgroundColor: Colors.red,
            ),
          );
          // Optionally navigate to login screen
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadBuktiScreen(
              buktiPembayaran: _buktiPembayaran!,
              idMetode: widget.idMetode,
              totalPembayaran: widget.totalPembayaran,
              pesanan: widget.pesanan,
              idPenyewa: userId,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveQRToGallery(String qrUrl) async {
    try {
      // Request storage permission
      if (await Permission.storage.request().isGranted) {
        final response = await http.get(Uri.parse(qrUrl));
        
        // Get downloads directory
        final directory = await getExternalStorageDirectory();
        final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${directory?.path}/$fileName';
        
        // Save file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Notify media scanner to make file visible in gallery
        await _scanFile(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code berhasil disimpan ke Downloads'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin penyimpanan diperlukan'))
        );
      }
    } catch (e) {
      print('Error saving QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan QR Code'))
      );
    }
  }

  Future<void> _scanFile(String path) async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('scanFile', {
          'path': path,
          'mimeType': 'image/png'
        });
      }
    } catch (e) {
      print('Error scanning file: $e');
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, size: 100, color: Colors.red);
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _saveQRToGallery(imageUrl),
                          icon: Icon(Icons.download),
                          label: Text('Simpan QR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A2F1C),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close),
                          label: Text('Tutup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    if (_metodePembayaran == null) return SizedBox.shrink();
    
    if (_metodePembayaran!['kategori'] == 'e-wallet') {
      final qrUrl = '${ApiConstants.baseUrlStorage}/storage/metode-pembayaran/qr/${_metodePembayaran!['qr_code'].split('/').last}';
      
      return Column(
        children: [
          Image.network(
            // Fix logo URL
            '${ApiConstants.baseUrlStorage}/storage/metode-pembayaran/logo/${_metodePembayaran!['logo'].split('/').last}',
            height: 60,
            width: 60,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading logo: $error');
              return Icon(Icons.error, size: 60, color: Colors.grey);
            },
          ),
          SizedBox(height: 16),
          Text(
            'Pembayaran via ${_metodePembayaran!['nama']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showFullImage(qrUrl),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                qrUrl,
                height: 250,
                width: 250,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading QR: $error');
                  return Icon(Icons.error, size: 250, color: Colors.grey);
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tekan QR untuk memperbesar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Image.network(
            // Fix logo URL for bank method
            '${ApiConstants.baseUrlStorage}/storage/metode-pembayaran/logo/${_metodePembayaran!['logo'].split('/').last}',
            height: 60,
            width: 60,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.error, size: 60, color: Colors.grey);
            },
          ),
          SizedBox(height: 16),
          Text(
            'Transfer Bank ${_metodePembayaran!['nama']}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Silahkan transfer sejumlah',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rp ${widget.totalPembayaran.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'ke nomor rekening',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                SelectableText(
                  _metodePembayaran!['nomor_rekening'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'a.n ${_metodePembayaran!['nama']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE7B789),
        title: Text(
          'Pembayaran',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _metodePembayaran == null 
              ? Center(
                  child: Text('Gagal memuat detail pembayaran'),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _metodePembayaran!['kategori'] == 'e-wallet'
                              ? 'Silahkan Scan QR dibawah ini untuk pembayaran'
                              : 'Silahkan transfer ke nomor rekening dibawah ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        _buildPaymentDetails(),
                        SizedBox(height: 24),
                        Text(
                          'Setelah melakukan pembayaran harap kirim bukti pembayaran dibawah ini',
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A2F1C),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Upload Bukti Pembayaran',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}