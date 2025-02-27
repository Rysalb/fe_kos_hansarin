import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/cart_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/users/order_menu/konfirmasi_pesanan_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE7B789),
        title: Text(
          'Keranjangku',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cartService.items.isEmpty
          ? Center(
              child: Text(
                'Keranjang masih kosong',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _cartService.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartService.items[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(12),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image with fixed size
                            Container(
                              width: 60,
                              height: 60,
                              child: Image.network(
                                item.fotoMakanan,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/pesanmakan.png', // Change to existing asset
                                    width: 60,
                                    height: 60,
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            // Details section with Expanded
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.namaMakanan,
                                    style: TextStyle(
                                      fontSize: 14, // Reduced font size
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    currencyFormatter.format(item.harga),
                                    style: TextStyle(
                                      fontSize: 12, // Reduced font size
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity controls
                            Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, size: 20), // Reduced icon size
                                    padding: EdgeInsets.all(4), // Reduced padding
                                    constraints: BoxConstraints(), // Remove minimum constraints
                                    onPressed: () {
                                      setState(() {
                                        _cartService.updateItemQuantity(
                                          item.idMakanan,
                                          item.jumlah - 1,
                                        );
                                      });
                                    },
                                  ),
                                  Text(
                                    '${item.jumlah}x',
                                    style: TextStyle(fontSize: 14), // Reduced font size
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add, size: 20), // Reduced icon size
                                    padding: EdgeInsets.all(4), // Reduced padding
                                    constraints: BoxConstraints(), // Remove minimum constraints
                                    onPressed: () {
                                      setState(() {
                                        _cartService.updateItemQuantity(
                                          item.idMakanan,
                                          item.jumlah + 1,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            currencyFormatter.format(_cartService.totalHarga),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Implement checkout logic
                           Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => KonfirmasiPesananScreen(),
    ),
  );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A2F1C),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}