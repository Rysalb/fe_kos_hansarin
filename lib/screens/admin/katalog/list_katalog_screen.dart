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
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _katalogList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.kategori.toLowerCase() == 'makanan' 
                            ? Icons.restaurant_menu 
                            : Icons.local_drink,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum menambahkan menu ${widget.kategori.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tambahkan menu ${widget.kategori.toLowerCase()} baru',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Adjusted ratio
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 8,
                                            width: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: item['status'] == 'tersedia' ? Colors.green : Colors.red,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item['status'].toString().replaceAll('_', ' '),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Stok: ${item['stock'] ?? 0}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(double.parse(item['harga'].toString())),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActionButton(
                                      onPressed: () => _hapusItem(item['id_makanan']),
                                      icon: Icons.delete_outline,
                                      label: 'Hapus',
                                      color: Colors.red,
                                    ),
                                    _buildActionButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UbahMenuScreen(menu: item),
                                          ),
                                        );
                                        if (result == true) _loadKatalog();
                                      },
                                      icon: Icons.edit_outlined,
                                      label: 'Ubah',
                                      color: Color(0xFFE7B789),
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

  // Add this new widget for compact action buttons
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 50, // Smaller fixed width
      height: 45, // Fixed height
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}