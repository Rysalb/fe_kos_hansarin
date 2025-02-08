import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/nomor_penting_service.dart';

class TambahNomorPentingScreen extends StatefulWidget {
  @override
  _TambahNomorPentingScreenState createState() => _TambahNomorPentingScreenState();
}

class _TambahNomorPentingScreenState extends State<TambahNomorPentingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorPentingService = NomorPentingService();
  final _namaKontakController = TextEditingController();
  final _nomorWAController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitNomorPenting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _nomorPentingService.createNomorPenting({
        'nama_kontak': _namaKontakController.text,
        'nomor_telepon': _nomorWAController.text,
        'kategori': 'WhatsApp',
      });

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan nomor penting')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Tambah Nomor Penting',
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
            children: [
              TextFormField(
                controller: _namaKontakController,
                decoration: InputDecoration(
                  labelText: 'Nama Kontak',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kontak harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nomorWAController,
                decoration: InputDecoration(
                  labelText: 'Nomor WA',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor WA harus diisi';
                  }
                  // Validasi format nomor telepon Indonesia
                  if (!value.startsWith('62')) {
                    return 'Nomor harus diawali dengan 62';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitNomorPenting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A2F1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
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

  @override
  void dispose() {
    _namaKontakController.dispose();
    _nomorWAController.dispose();
    super.dispose();
  }
} 