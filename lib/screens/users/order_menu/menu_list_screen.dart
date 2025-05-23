import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/katalog_makanan_service.dart';
import 'package:proyekkos/screens/users/order_menu/cart_screen.dart';
import 'package:proyekkos/data/models/cart_item.dart';
import 'package:proyekkos/data/services/cart_service.dart';
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
  final CartService _cartService = CartService();
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
              'harga': harga,
              'id_makanan': item['id_makanan'] ?? 0,
              'status': item['status'] ?? 'tidak_tersedia',
              'stock': item['stock'] ?? 0, // Add stock information
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

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
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
               Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CartScreen(),
          ),
        );
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
                    childAspectRatio: 0.7, // Adjusted from 0.8 to 0.7 to give more height
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
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreview(
                                context, 
                                _service.getImageUrl(menu['foto_makanan'])
                              ),
                              child: Image.network(
                                _service.getImageUrl(menu['foto_makanan']),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/pesanmakan.png',
                                    height: 100,
                                    width: 100,
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                menu['nama_makanan'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(menu['harga'] as num),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 6,
                                  width: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: menu['status'] == 'tersedia' ? Colors.green : Colors.red,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  menu['status'].toString().replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Stok: ${menu['stock'] ?? 0}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Add to cart logic
                                        _cartService.addItem(
      CartItem(
        idMakanan: menu['id_makanan'],
        namaMakanan: menu['nama_makanan'],
        fotoMakanan: menu['foto_makanan'],
        harga: menu['harga'],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil ditambahkan ke keranjang'),
        duration: Duration(seconds: 1),
      ),
    );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF7FFF00),
                                      padding: EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Beli',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}