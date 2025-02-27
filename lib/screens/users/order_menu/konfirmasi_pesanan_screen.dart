import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/cart_service.dart';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/users/order_menu/pembayaran_screen.dart';


class KonfirmasiPesananScreen extends StatefulWidget {
  @override
  _KonfirmasiPesananScreenState createState() => _KonfirmasiPesananScreenState();
}

class _KonfirmasiPesananScreenState extends State<KonfirmasiPesananScreen> {
  final CartService _cartService = CartService();
  final MetodePembayaranService _metodePembayaranService = MetodePembayaranService();
  final TextEditingController _catatanController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String? _selectedMetodeId;
  String? _selectedMetodeNama; // Change to nullable String
  bool _isLoading = false;
  List<Map<String, dynamic>> _metodePembayaran = [];

  @override
  void initState() {
    super.initState();
    _loadMetodePembayaran();
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final data = await _metodePembayaranService.getAllMetodePembayaran();
      if (mounted) {
        setState(() {
          _metodePembayaran = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat metode pembayaran: $e')),
        );
      }
    }
  }

  void _showMetodePembayaran() {
    if (_metodePembayaran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Metode pembayaran belum dibuat')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _metodePembayaran.length,
                  itemBuilder: (context, index) {
                    final metode = _metodePembayaran[index];
                    return _buildPaymentMethodItem(metode);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> metode) {
    return ListTile(
      leading: Image.network(
        metode['logo'] ?? '',
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => Icon(Icons.payment),
      ),
      title: Text(metode['nama'] ?? ''),
      subtitle: Text(metode['kategori'] == 'bank' ? 'Transfer Bank' : 'E-Wallet'),
      onTap: () {
        setState(() {
          _selectedMetodeId = metode['id_metode']?.toString();
          _selectedMetodeNama = metode['nama'];
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _buatPesanan() async {
    if (_selectedMetodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PembayaranScreen(
          idMetode: _selectedMetodeId!,
          totalPembayaran: _cartService.totalHarga.toDouble(),
          pesanan: _cartService.items.map((item) => {
            'id_makanan': item.idMakanan,
            'jumlah': item.jumlah,
            'total_harga': item.totalHarga,
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE7B789),
        title: Text(
          'Konfirmasi Pesanan',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cart items
            ..._cartService.items.map((item) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _cartService.getFullImageUrl(item.fotoMakanan),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error'); // Add debug print
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.fastfood, color: Colors.grey),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaMakanan,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(item.harga),
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${item.jumlah}x',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Total price
                  Text(
                    currencyFormatter.format(item.totalHarga),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
            
            SizedBox(height: 24),
            
            // Notes
            Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _catatanController,
              decoration: InputDecoration(
                hintText: 'Mohon Tinggalkan catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            SizedBox(height: 24),
            
            // Payment method
            InkWell(
              onTap: _showMetodePembayaran,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payment),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(_selectedMetodeNama ?? 'Pilih Metode Pembayaran'),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currencyFormatter.format(_cartService.totalHarga),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _buatPesanan,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A2F1C),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Buat Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}