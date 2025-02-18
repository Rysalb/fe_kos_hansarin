import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/katalog_makanan_service.dart';
import 'package:proyekkos/screens/admin/katalog/kelola_katalog_screen.dart';
import 'package:proyekkos/screens/admin/katalog/list_katalog_screen.dart';

class KatalogMakananScreen extends StatefulWidget {
  @override
  _KatalogMakananScreenState createState() => _KatalogMakananScreenState();
}

class _KatalogMakananScreenState extends State<KatalogMakananScreen> {
  final KatalogMakananService _service = KatalogMakananService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _makananList = [];
  List<Map<String, dynamic>> _minumanList = [];

  @override
  void initState() {
    super.initState();
    _loadKatalog();
  }

  Future<void> _loadKatalog() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAll();
      setState(() {
        _makananList = data.where((item) => item['kategori'] == 'makanan').toList();
        _minumanList = data.where((item) => item['kategori'] == 'minuman').toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat katalog')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKategoriCard('Makanan', _makananList.length),
                  SizedBox(height: 16),
                  _buildKategoriCard('Minuman', _minumanList.length),
                ],
              ),
            ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KelolaKatalogScreen(),
              ),
            );
            if (result == true) {
              _loadKatalog();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Image.asset('assets/images/add_icon.png'),
        ),
      ),
    );
  }

  Widget _buildKategoriCard(String kategori, int jumlah) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListKatalogScreen(
              kategori: kategori.toLowerCase(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFBE1CE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Text(
            kategori,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          trailing: Text(
            jumlah.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}