import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/peraturan_kos_service.dart';
import 'package:intl/intl.dart';

class TambahPeraturanKosScreen extends StatefulWidget {
  final Map<String, dynamic>? currentPeraturan;

  const TambahPeraturanKosScreen({Key? key, this.currentPeraturan}) : super(key: key);

  @override
  _TambahPeraturanKosScreenState createState() => _TambahPeraturanKosScreenState();
}

class _TambahPeraturanKosScreenState extends State<TambahPeraturanKosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _peraturanController = TextEditingController();
  final _peraturanKosService = PeraturanKosService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentPeraturan != null) {
      _peraturanController.text = widget.currentPeraturan!['isi_peraturan'];
    }
  }

  Future<void> _savePeraturan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'isi_peraturan': _peraturanController.text,
        'tanggal_dibuat': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      bool success;
      if (widget.currentPeraturan != null) {
        success = await _peraturanKosService.updatePeraturan(
          widget.currentPeraturan!['id_peraturan'],
          data,
        );
      } else {
        success = await _peraturanKosService.createPeraturan(data);
      }

      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan peraturan')),
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
          widget.currentPeraturan != null ? 'Ubah Peraturan' : 'Tambah Peraturan',
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
                controller: _peraturanController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Masukkan peraturan kos...\nContoh:\nDilarang merokok\nDilarang membawa hewan',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Peraturan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePeraturan,
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
    _peraturanController.dispose();
    super.dispose();
  }
} 