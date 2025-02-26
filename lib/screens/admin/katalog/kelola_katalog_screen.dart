import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/katalog_makanan_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class KelolaKatalogScreen extends StatefulWidget {
  @override
  _KelolaKatalogScreenState createState() => _KelolaKatalogScreenState();
}

class _KelolaKatalogScreenState extends State<KelolaKatalogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _stockController = TextEditingController();
  final _hargaController = TextEditingController();
  String _selectedKategori = 'makanan';
  File? _fotoMakanan;
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
      final data = await _service.getAll();
      setState(() => _katalogList = data);
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
      appBar: AppBar(
        title: Text('Kelola Katalog Makanan & Minuman', style: TextStyle(fontSize: 15),),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Menu',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Nama menu harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: InputDecoration(
                  labelText: 'Pilih Kategori',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(value: 'makanan', child: Text('Makanan')),
                  DropdownMenuItem(value: 'minuman', child: Text('Minuman')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedKategori = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Stock harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _hargaController,
                decoration: InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Harga harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _fotoMakanan != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _fotoMakanan!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Upload Foto Menu',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFBE1CE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _fotoMakanan = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_fotoMakanan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto menu harus dipilih')),
        );
        return;
      }

      try {
       await _service.create(
        nama: _namaController.text,
        harga: double.parse(_hargaController.text),
        kategori: _selectedKategori,
        deskripsi: '', // Bisa ditambahkan field deskripsi jika diperlukan
        fotoMakanan: _fotoMakanan!,
        stock: int.parse(_stockController.text), // Add stock parameter
        status: 'tersedia',
        );
        
        Navigator.pop(context, true);
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan menu')),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _stockController.dispose();
    _hargaController.dispose();
    super.dispose();
  }
} 