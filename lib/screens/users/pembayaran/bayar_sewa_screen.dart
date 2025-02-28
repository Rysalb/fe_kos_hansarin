import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:proyekkos/screens/users/pembayaran/upload_bukti_bayar_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.manageExternalStorage, // Add this permission
      ].request();

      if (statuses[Permission.storage]!.isGranted || 
          statuses[Permission.photos]!.isGranted) {
        final response = await http.get(Uri.parse(qrUrl));
        
        // Get the Downloads directory
        Directory? directory;
        if (Platform.isAndroid) {
          // Get the Downloads directory path
          directory = Directory('/storage/emulated/0/Download');
          // Create directory if it doesn't exist
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
          final filePath = '${directory.path}/$fileName';
          
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Notify media scanner
          await _scanFile(filePath);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR Code berhasil disimpan ke folder Download'),
              action: SnackBarAction(
                label: 'Lihat',
                onPressed: () async {
                  // Open file explorer to Downloads folder
                  if (Platform.isAndroid) {
                    await _openDownloadsFolder();
                  }
                },
              ),
            )
          );
        }
      } else {
        // Show settings dialog
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Izin Diperlukan'),
            content: Text('Aplikasi memerlukan izin untuk menyimpan QR Code ke Downloads.'),
            actions: [
              TextButton(
                child: Text('Tidak'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('Buka Pengaturan'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
    } catch (e) {
      print('Error saving QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan QR Code: ${e.toString()}'))
      );
    }
  }

  Future<void> _scanFile(String path) async {
    try {
      if (Platform.isAndroid) {
        final platformChannel = MethodChannel('com.example.proyekkos/media_scanner');
        await platformChannel.invokeMethod('scanFile', {
          'path': path,
          'mimeType': 'image/png'
        });
      }
    } catch (e) {
      print('Error scanning file: $e');
    }
  }

  // Add method to open Downloads folder
  Future<void> _openDownloadsFolder() async {
    try {
      final platform = MethodChannel('com.example.proyekkos/file_manager');
      await platform.invokeMethod('openDownloads');
    } catch (e) {
      print('Error opening Downloads folder: $e');
    }
  }

  Widget _buildPaymentImage(Map<String, dynamic> metode) {
    return metode['kategori'] == 'e-wallet' && metode['qr_code'] != null 
      ? Image.network(
          metode['qr_code'],
          height: 200,
          width: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading QR: $error');
            // Return placeholder with retry button
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 50, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'Gagal memuat QR Code',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Force rebuild widget to retry loading image
                    setState(() {});
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Muat ulang'),
                ),
              ],
            );
          },
          // Add loading placeholder
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        )
      : SizedBox.shrink();
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
              ] else if (metode['kategori'] == 'e-wallet') ...[
                _buildPaymentImage(metode),
                if (metode['qr_code'] != null) ...[
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _saveQRToGallery(metode['qr_code']),
                    child: Text('Simpan QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A2F1C),
                    ),
                  ),
                ],
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
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
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