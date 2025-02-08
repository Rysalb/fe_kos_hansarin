import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/nomor_penting_service.dart';

class UbahNomorPentingScreen extends StatefulWidget {
  final Map<String, dynamic> nomorPenting;

  const UbahNomorPentingScreen({Key? key, required this.nomorPenting}) : super(key: key);

  @override
  _UbahNomorPentingScreenState createState() => _UbahNomorPentingScreenState();
}

class _UbahNomorPentingScreenState extends State<UbahNomorPentingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomorPentingService = NomorPentingService();
  final _namaKontakController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  String _selectedKategori = 'WhatsApp';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaKontakController.text = widget.nomorPenting['nama_kontak'];
    _nomorTeleponController.text = widget.nomorPenting['nomor_telepon'];
    _selectedKategori = widget.nomorPenting['kategori'] ?? 'WhatsApp';
  }

  Future<void> _updateNomorPenting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _nomorPentingService.updateNomorPenting(
        widget.nomorPenting['id_nomor'],
        {
          'nama_kontak': _namaKontakController.text,
          'nomor_telepon': _nomorTeleponController.text,
          'kategori': _selectedKategori,
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor penting berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui nomor penting')),
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
          'Ubah Nomor Penting',
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
                controller: _nomorTeleponController,
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
                  onPressed: _isLoading ? null : _updateNomorPenting,
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
    _nomorTeleponController.dispose();
    super.dispose();
  }
} 