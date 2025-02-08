import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';

class TambahMetodePembayaranScreen extends StatefulWidget {
  @override
  _TambahMetodePembayaranScreenState createState() => _TambahMetodePembayaranScreenState();
}

class _TambahMetodePembayaranScreenState extends State<TambahMetodePembayaranScreen> {
  final _formKey = GlobalKey<FormState>();
  final MetodePembayaranService _metodePembayaranService = MetodePembayaranService();
  
  String? _selectedKategori;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nomorRekeningController = TextEditingController();
  File? _logoFile;
  File? _qrCodeFile;
  bool _isLoading = false;

  Future<void> _pickImage(bool isLogo) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(image.path);
        } else {
          _qrCodeFile = File(image.path);
        }
      });
    }
  }

  Future<void> _simpanMetodePembayaran() async {
    if (!_formKey.currentState!.validate()) return;
    if (_logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon pilih logo pembayaran')),
      );
      return;
    }

    if (_selectedKategori == 'e-wallet' && _qrCodeFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon pilih QR Code untuk e-wallet')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data = {
        'kategori': _selectedKategori,
        'nama': _selectedKategori == 'bank' 
            ? _namaController.text 
            : _namaController.text,
        'logo': _logoFile,
      };

      if (_selectedKategori == 'bank') {
        data['nomor_rekening'] = _nomorRekeningController.text;
      } else {
        data['qr_code'] = _qrCodeFile;
      }

      await _metodePembayaranService.addMetodePembayaran(data);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Metode pembayaran berhasil ditambahkan')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan metode pembayaran: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Tambahkan Metode Pembayaran',
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
              // Info dialog implementation
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('--Pilih Kategori--'),
                          value: _selectedKategori,
                          items: [
                            DropdownMenuItem(value: 'bank', child: Text('Bank')),
                            DropdownMenuItem(value: 'e-wallet', child: Text('E-Wallet')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedKategori = value;
                              _namaController.clear();
                              _nomorRekeningController.clear();
                              _qrCodeFile = null;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_selectedKategori != null) ...[
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: _selectedKategori == 'bank' ? 'Nama Bank' : 'Nama E-Wallet',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Field ini tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      if (_selectedKategori == 'bank')
                        TextFormField(
                          controller: _nomorRekeningController,
                          decoration: InputDecoration(
                            labelText: 'Nomor Rekening',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Field ini tidak boleh kosong';
                            }
                            return null;
                          },
                        )
                      else
                        InkWell(
                          onTap: () => _pickImage(false),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _qrCodeFile != null
                                        ? 'QR Code dipilih'
                                        : 'Masukkan Gambar QR E-wallet',
                                    style: TextStyle(
                                      color: _qrCodeFile != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (_qrCodeFile != null)
                                  Icon(Icons.check_circle, color: Colors.green),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () => _pickImage(true),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _logoFile != null
                                      ? 'Logo dipilih'
                                      : 'Masukkan Gambar Logo Pembayaran',
                                  style: TextStyle(
                                    color: _logoFile != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (_logoFile != null)
                                Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _simpanMetodePembayaran,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A2F1C),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomorRekeningController.dispose();
    super.dispose();
  }
} 