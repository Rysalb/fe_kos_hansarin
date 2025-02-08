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

  Future<void> _deleteMetodePembayaran(int id) async {
    try {
      final success = await _metodePembayaranService.deleteMetodePembayaran(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Metode pembayaran berhasil dihapus')),
        );
        _loadMetodePembayaran(); // Refresh data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus metode pembayaran')),
      );
    }
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
              // Tambahkan informasi dialog jika diperlukan
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
                        key: Key(metode['id'].toString()),
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
                          _deleteMetodePembayaran(metode['id']);
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