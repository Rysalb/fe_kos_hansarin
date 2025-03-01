import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/nomor_penting_service.dart';
import 'package:proyekkos/screens/admin/nomor_penting/tambah_nomor_penting_screen.dart';
import 'package:proyekkos/screens/admin/nomor_penting/ubah_nomor_penting_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class NomorPentingScreen extends StatefulWidget {
  @override
  _NomorPentingScreenState createState() => _NomorPentingScreenState();
}

class _NomorPentingScreenState extends State<NomorPentingScreen> {
  final NomorPentingService _nomorPentingService = NomorPentingService();
  List<Map<String, dynamic>> _nomorPentingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNomorPenting();
  }

  Future<void> _loadNomorPenting() async {
    try {
      final data = await _nomorPentingService.getAllNomorPenting();
      setState(() {
        _nomorPentingList = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading nomor penting: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final whatsappUrl = "whatsapp://send?phone=$phoneNumber";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp tidak terinstall')),
      );
    }
  }

  Future<void> _deleteNomorPenting(int id) async {
    try {
      final success = await _nomorPentingService.deleteNomorPenting(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor penting berhasil dihapus')),
        );
        _loadNomorPenting();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus nomor penting')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
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
          'Nomor Penting',
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
                            'Menambah Nomor Penting:',
                            [
                              '1. Tekan tombol + di pojok kanan bawah',
                              '2. Isi nama kontak',
                              '3. Masukkan nomor WhatsApp (diawali 62)',
                              '4. Tekan tombol Simpan',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Mengubah Nomor Penting:',
                            [
                              '1. Tekan nomor yang ingin diubah',
                              '2. Ubah informasi yang diinginkan',
                              '3. Tekan tombol Simpan',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Menghapus Nomor Penting:',
                            [
                              '1. Geser item ke kiri',
                              '2. Konfirmasi penghapusan pada dialog',
                              '3. Nomor akan terhapus dari sistem',
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
          : _nomorPentingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum ada nomor penting yang ditambahkan',
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
                  padding: EdgeInsets.all(16),
                  itemCount: _nomorPentingList.length,
                  itemBuilder: (context, index) {
                    final nomor = _nomorPentingList[index];
                    return Dismissible(
                      key: Key(nomor['id_nomor'].toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Konfirmasi'),
                              content: Text('Yakin ingin menghapus nomor ini?'),
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
                        _deleteNomorPenting(nomor['id_nomor']);
                      },
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UbahNomorPentingScreen(
                                nomorPenting: nomor,
                              ),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _loadNomorPenting();
                            }
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFE5CC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              nomor['nama_kontak'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(nomor['nomor_telepon'] ?? ''),
                            trailing: IconButton(
                              icon: Image.asset(
                                'assets/images/dashboard_icon/wa.png',
                                width: 24,
                                height: 24,
                              ),
                              onPressed: () => _launchWhatsApp(nomor['nomor_telepon']),
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
              builder: (context) => TambahNomorPentingScreen(),
            ),
          ).then((value) {
            if (value == true) {
              _loadNomorPenting();
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