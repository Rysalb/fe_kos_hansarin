import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/katalog_makanan_service.dart';
import 'package:intl/intl.dart';

class MenuListScreen extends StatefulWidget {
  final String kategori;
  final String title;

  MenuListScreen({
    required this.kategori,
    required this.title,
  });

  @override
  _MenuListScreenState createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final KatalogMakananService _service = KatalogMakananService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _menuList = [];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final data = await _service.getByKategori(widget.kategori);
      if (mounted) {
        setState(() {
          _menuList = data.map((item) {
            // Convert harga from String to double/int
            var harga = 0;
            if (item['harga'] != null) {
              if (item['harga'] is String) {
                harga = double.tryParse(item['harga'])?.toInt() ?? 0;
              } else {
                harga = item['harga'];
              }
            }

            return {
              'foto_makanan': item['foto_makanan'] ?? '',
              'nama_makanan': item['nama_makanan'] ?? '',
              'harga': harga,  // Store as number
              'id_makanan': item['id_makanan'] ?? 0,
              'status': item['status'] ?? 'tidak_tersedia',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading menu: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat menu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE7B789),
        title: Text(
          'Menu ${widget.title}',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/troli.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              // Navigate to cart
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _menuList.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada menu ${widget.title} yang tersedia',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _menuList.length,
                  itemBuilder: (context, index) {
                    final menu = _menuList[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            _service.getImageUrl(menu['foto_makanan']), // Gunakan helper method untuk URL gambar
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/pesanmakan.png',
                                height: 80,
                                width: 80,
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              menu['nama_makanan'] ?? '', // Sesuaikan dengan nama field yang benar
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(menu['harga'] as num), // Cast to num type
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Add to cart logic
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF7FFF00),
                              minimumSize: Size(100, 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Beli',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
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