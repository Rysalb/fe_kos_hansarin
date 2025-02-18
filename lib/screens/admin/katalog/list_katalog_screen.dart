import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/katalog_makanan_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/admin/katalog/ubah_menu_screen.dart';

class ListKatalogScreen extends StatefulWidget {
  final String kategori;

  const ListKatalogScreen({Key? key, required this.kategori}) : super(key: key);

  @override
  _ListKatalogScreenState createState() => _ListKatalogScreenState();
}

class _ListKatalogScreenState extends State<ListKatalogScreen> {
  final KatalogMakananService _service = KatalogMakananService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _katalogList = [];

  @override
  void initState() {
    super.initState();
    _loadKatalog();
  }

  Future<void> _loadKatalog() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getByKategori(widget.kategori);
      setState(() => _katalogList = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus menu ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.delete(id);
        _loadKatalog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus menu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List ${widget.kategori}'),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Tambahkan fungsi info jika diperlukan
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _katalogList.length,
              itemBuilder: (context, index) {
                final item = _katalogList[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                _service.getImageUrl(item['foto_makanan']),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama_makanan'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Status: ${item['status']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(double.parse(item['harga'].toString())),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _hapusItem(item['id_makanan']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: Size(60, 30),
                                  ),
                                  child: Text(
                                    'Hapus',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UbahMenuScreen(menu: item),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadKatalog();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFE7B789),
                                    minimumSize: Size(60, 30),
                                  ),
                                  child: Text(
                                    'Ubah',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
} 