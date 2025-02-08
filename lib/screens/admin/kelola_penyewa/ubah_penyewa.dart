import 'package:flutter/material.dart';
import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class UbahPenyewaPage extends StatefulWidget {
  final int idPenyewa;

  UbahPenyewaPage({required this.idPenyewa});

  @override
  _UbahPenyewaPageState createState() => _UbahPenyewaPageState();
}

class _UbahPenyewaPageState extends State<UbahPenyewaPage> {
  final PenyewaService _penyewaService = PenyewaService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _penyewaDetail;
  
  // Controllers
  final _namaController = TextEditingController();
  final _asalController = TextEditingController();
  final _tanggalMasukController = TextEditingController();
  final _tanggalKeluarController = TextEditingController();
  final _noHPController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _fotoKtpUrl;
  File? _fotoKtpFile;

  @override
  void initState() {
    super.initState();
    _fetchPenyewaDetail();
  }

  Future<void> _fetchPenyewaDetail() async {
    try {
      final detail = await _penyewaService.getPenyewaById(widget.idPenyewa);
      setState(() {
        _penyewaDetail = detail;
        _namaController.text = detail['user']['name'];
        _asalController.text = detail['alamat_asal'];
        _tanggalMasukController.text = DateFormat('dd MMMM yyyy')
            .format(DateTime.parse(detail['tanggal_masuk']));
        _tanggalKeluarController.text = DateFormat('dd MMMM yyyy')
            .format(DateTime.parse(detail['tanggal_keluar']));
        _noHPController.text = detail['nomor_wa'];
        _emailController.text = detail['user']['email'];
        
        // Update cara mengambil foto_ktp
        if (detail['foto_ktp'] != null) {
          _fotoKtpUrl = detail['foto_ktp'].toString().split('/').last;
          print('Loaded KTP URL: $_fotoKtpUrl'); // Debug
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching penyewa detail: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isEntryDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isEntryDate) {
          _tanggalMasukController.text = DateFormat('dd MMMM yyyy').format(picked);
        } else {
          _tanggalKeluarController.text = DateFormat('dd MMMM yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _fotoKtpFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _updatePenyewa() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        
        final updatedData = {
          'name': _namaController.text,
          'alamat_asal': _asalController.text,
          'tanggal_masuk': DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd MMMM yyyy').parse(_tanggalMasukController.text)),
          'tanggal_keluar': DateFormat('yyyy-MM-dd')
              .format(DateFormat('dd MMMM yyyy').parse(_tanggalKeluarController.text)),
          'nomor_wa': _noHPController.text,
          'email': _emailController.text,
          'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
        };

        // Hapus nilai null dari updatedData
        updatedData.removeWhere((key, value) => value == null);

        if (_fotoKtpFile != null) {
          await _penyewaService.updatePenyewaWithImage(
            widget.idPenyewa, 
            updatedData,
            _fotoKtpFile!
          );
        } else {
          await _penyewaService.updatePenyewa(widget.idPenyewa, updatedData);
        }
        
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data penyewa berhasil diperbarui')),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui data: $e')),
        );
      }
    }
  }

  // Method untuk menampilkan gambar dalam dialog
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            width: double.infinity,
            height: 400,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
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
              errorBuilder: (context, error, stackTrace) {
                return Center(child: Text('Gagal memuat gambar'));
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildKtpImage() {
    if (_fotoKtpFile != null) {
      return GestureDetector(
        onTap: () {
          _showFullImage(_fotoKtpFile!.path); // Tampilkan gambar lokal
        },
        child: Image.file(
          _fotoKtpFile!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_fotoKtpUrl != null && _fotoKtpUrl!.isNotEmpty) {
      final fullImageUrl = '${ApiConstants.baseUrlimage}/storage/ktp/${_fotoKtpUrl}';
      print('KTP URL: $fullImageUrl'); // Debug URL
      return GestureDetector(
        onTap: () {
          _showFullImage(fullImageUrl); // Tampilkan gambar dari URL
        },
        child: Image.network(
          fullImageUrl,
          fit: BoxFit.cover,
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
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error'); // Debug error
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(height: 8),
                Text('Gagal memuat gambar', textAlign: TextAlign.center),
              ],
            );
          },
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('Belum ada foto KTP', textAlign: TextAlign.center),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Ubah Data ${_penyewaDetail?['unit_kamar']['nomor_kamar'] ?? ''}',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildKtpImage(),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_library),
                      label: Text('Pilih Foto KTP'),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _asalController,
                      decoration: InputDecoration(
                        labelText: 'Asal',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Asal tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _tanggalMasukController,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Masuk',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, true),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _tanggalKeluarController,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Keluar',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, false),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _noHPController,
                      decoration: InputDecoration(
                        labelText: 'No HP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? 'No HP tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty ? 'Email tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password (Kosongkan jika tidak diubah)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.visibility),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updatePenyewa,
                        child: Text('Simpan', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE7B789),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _asalController.dispose();
    _tanggalMasukController.dispose();
    _tanggalKeluarController.dispose();
    _noHPController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 