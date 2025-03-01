import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';
import 'package:proyekkos/screens/admin/metode_pembayaran/tambah_metode_pembayaran_screen.dart';
import 'package:proyekkos/screens/admin/metode_pembayaran/ubah_metode_pembayaran_screen.dart';

class MetodePembayaranScreen extends StatefulWidget {
  @override
  _MetodePembayaranScreenState createState() => _MetodePembayaranScreenState();
}

class _MetodePembayaranScreenState extends State<MetodePembayaranScreen> {
  final MetodePembayaranService _metodePembayaranService = MetodePembayaranService();
  List<Map<String, dynamic>> _metodePembayaran = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetodePembayaran();
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final data = await _metodePembayaranService.getAllMetodePembayaran();
      setState(() {
        _metodePembayaran = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading metode pembayaran: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMetodePembayaran(dynamic id) async {
    try {
      // Add null check and type conversion
      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID metode pembayaran tidak valid')),
        );
        return;
      }

      // Convert id to int safely
      final int metodeId = id is int ? id : int.tryParse(id.toString()) ?? -1;
      if (metodeId == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID metode pembayaran tidak valid')),
        );
        return;
      }

      final success = await _metodePembayaranService.deleteMetodePembayaran(metodeId);
      if (success) {
        setState(() {
          _metodePembayaran.removeWhere((item) => item['id_metode'] == metodeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Metode pembayaran berhasil dihapus')),
        );
      } else {
        throw Exception('Gagal menghapus metode pembayaran');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus metode pembayaran')),
      );
    }
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A2F1C),
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Metode Pembayaran',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Panduan Penggunaan',
                      style: TextStyle(
                        color: Color(0xFF4A2F1C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoSection(
                            'Menambah Metode Pembayaran:',
                            [
                              '1. Tekan tombol + di pojok kanan bawah',
                              '2. Isi nama metode pembayaran',
                              '3. Pilih kategori (Bank/E-wallet)',
                              '4. Upload logo metode pembayaran',
                              '5. Isi nomor rekening (untuk Bank)',
                              '6. Upload QR Code (untuk E-wallet)',
                              '7. Tekan tombol Simpan',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Mengubah Metode Pembayaran:',
                            [
                              '1. Tekan metode pembayaran yang ingin diubah',
                              '2. Ubah informasi yang diinginkan',
                              '3. Tekan tombol Simpan untuk menyimpan perubahan',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Menghapus Metode Pembayaran:',
                            [
                              '1. Geser item ke kiri',
                              '2. Konfirmasi penghapusan pada dialog yang muncul',
                              '3. Metode pembayaran akan terhapus dari sistem',
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'Tutup',
                          style: TextStyle(color: Color(0xFF4A2F1C)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: Color(0xFFFFF8E7),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _metodePembayaran.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum ada metode pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tekan tombol + untuk menambahkan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _metodePembayaran.length,
                  itemBuilder: (context, index) {
                    final metode = _metodePembayaran[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Dismissible(
                        key: Key(metode['id_metode']?.toString() ?? ''), // Update key to use id_metode
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.white),
                              Text('Hapus', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Konfirmasi'),
                                content: Text('Yakin ingin menghapus metode pembayaran ini?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteMetodePembayaran(metode['id_metode']); // Use id_metode
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UbahMetodePembayaranScreen(
                                  metodePembayaran: metode,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                _loadMetodePembayaran();
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFFE5CC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Image.network(
                                metode['logo'],
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.error),
                              ),
                              title: Text(
                                metode['nama'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahMetodePembayaranScreen(),
            ),
          ).then((value) {
            if (value == true) {
              _loadMetodePembayaran(); // Refresh data setelah menambah
            }
          });
        },
        child: Image.asset(
          'assets/images/add_icon.png',
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}