import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:proyekkos/data/services/metode_pembayaran_service.dart';
import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/widgets/image_preview_dialog.dart';

class UbahMetodePembayaranScreen extends StatefulWidget {
  final Map<String, dynamic> metodePembayaran;

  const UbahMetodePembayaranScreen({Key? key, required this.metodePembayaran}) : super(key: key);

  @override
  _UbahMetodePembayaranScreenState createState() => _UbahMetodePembayaranScreenState();
}

class _UbahMetodePembayaranScreenState extends State<UbahMetodePembayaranScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedKategori;
  late TextEditingController _namaController;
  late TextEditingController _nomorRekeningController;
  File? _logoFile;
  File? _qrCodeFile;
  bool _isLoading = false;
  final MetodePembayaranService _metodePembayaranService = MetodePembayaranService();

  @override
  void initState() {
    super.initState();
    _selectedKategori = widget.metodePembayaran['kategori'];
    _namaController = TextEditingController(text: widget.metodePembayaran['nama']);
    _nomorRekeningController = TextEditingController(text: widget.metodePembayaran['nomor_rekening']);
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        if (type == 'logo') {
          _logoFile = File(image.path);
        } else {
          _qrCodeFile = File(image.path);
        }
      });
    }
  }

  Future<void> _updateMetodePembayaran() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'kategori': _selectedKategori,
        'nama': _namaController.text,
        'nomor_rekening': _selectedKategori == 'bank' ? _nomorRekeningController.text : null,
        'logo': _logoFile,
        'qr_code': _selectedKategori == 'e-wallet' ? _qrCodeFile : null,
      };

      final success = await _metodePembayaranService.updateMetodePembayaran(
        widget.metodePembayaran['id'],
        data,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Metode pembayaran berhasil diperbarui')),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui metode pembayaran')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImagePreview(String imageUrl, {bool isNetworkImage = true, String? imagePath}) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        imageUrl: imageUrl,
        isNetworkImage: isNetworkImage,
        imagePath: imagePath,
      ),
    );
  }

  Widget _buildQRPreview() {
    if (_qrCodeFile != null) {
      return GestureDetector(
        onTap: () => _showImagePreview(
          '',
          isNetworkImage: false,
          imagePath: _qrCodeFile!.path,
        ),
        child: Container(
          height: 200,
          width: 200,
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _qrCodeFile!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else if (widget.metodePembayaran['qr_code'] != null) {
      final qrUrl = _metodePembayaranService.getImageUrl(widget.metodePembayaran['qr_code']);
      return GestureDetector(
        onTap: () => _showImagePreview(qrUrl),
        child: Container(
          height: 200,
          width: 200,
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              qrUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading QR: $error');
                return Center(
                  child: Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildLogoPreview() {
    if (_logoFile != null) {
      return GestureDetector(
        onTap: () => _showImagePreview(
          '',
          isNetworkImage: false,
          imagePath: _logoFile!.path,
        ),
        child: Container(
          height: 100,
          width: 100,
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _logoFile!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else if (widget.metodePembayaran['logo'] != null) {
      final logoUrl = _metodePembayaranService.getImageUrl(widget.metodePembayaran['logo']);
      return GestureDetector(
        onTap: () => _showImagePreview(logoUrl),
        child: Container(
          height: 100,
          width: 100,
          margin: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading logo: $error');
                return Center(
                  child: Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Ubah Metode Pembayaran',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: InputDecoration(
                  labelText: 'Pilih Kategori',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'e-wallet', child: Text('E-Wallet')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedKategori = value!;
                  });
                },
              ),
              SizedBox(height: 16),
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
                      return 'Nomor rekening tidak boleh kosong';
                    }
                    return null;
                  },
                )
              else ...[
                _buildQRPreview(),
                OutlinedButton(
                  onPressed: () => _pickImage('qr'),
                  child: Text('Masukkan Gambar QR E-wallet'),
                ),
              ],
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _pickImage('logo'),
                child: Text('Masukkan Gambar Logo Pembayaran'),
              ),
              _buildLogoPreview(),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A2F1C),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _updateMetodePembayaran,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Simpan', style: TextStyle(color: Colors.white)),
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
    _nomorRekeningController.dispose();
    super.dispose();
  }
} 