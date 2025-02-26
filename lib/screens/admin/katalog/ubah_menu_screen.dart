import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/katalog_makanan_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UbahMenuScreen extends StatefulWidget {
  final Map<String, dynamic> menu;

  const UbahMenuScreen({Key? key, required this.menu}) : super(key: key);

  @override
  _UbahMenuScreenState createState() => _UbahMenuScreenState();
}

class _UbahMenuScreenState extends State<UbahMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _stockController = TextEditingController();
  final _hargaController = TextEditingController();
  late String _selectedKategori;
  late String _selectedStatus;
  File? _fotoMakanan;
  final KatalogMakananService _service = KatalogMakananService();

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.menu['nama_makanan'];
    _stockController.text = widget.menu['stock']?.toString() ?? '';
    _hargaController.text = widget.menu['harga'].toString();
    _selectedKategori = widget.menu['kategori'];
    _selectedStatus = widget.menu['status'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubah Menu'),
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(value: 'tersedia', child: Text('Tersedia')),
                  DropdownMenuItem(value: 'tidak_tersedia', child: Text('Tidak Tersedia')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _fotoMakanan != null
                    ? Image.file(_fotoMakanan!, fit: BoxFit.cover)
                    : widget.menu['foto_makanan'] != null
                        ? Image.network(
                            _service.getImageUrl(widget.menu['foto_makanan']),
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image, size: 50),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey),
                  ),
                ),
                child: Text(
                  'Upload Foto Menu',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateMenu,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFBE1CE),
                  minimumSize: Size(double.infinity, 50),
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

  Future<void> _updateMenu() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _service.update(
        id: widget.menu['id_makanan'],
        nama: _namaController.text,
        harga: double.parse(_hargaController.text),
        kategori: _selectedKategori,
        deskripsi: '',
        fotoMakanan: _fotoMakanan,
        stock: int.parse(_stockController.text), // Add stock parameter
        status: _selectedStatus,
        );
        
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu berhasil diupdate')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupdate menu')),
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