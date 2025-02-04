import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/kamar_service.dart';
import 'package:intl/intl.dart';

class TambahKamarPage extends StatefulWidget {
  @override
  _TambahKamarPageState createState() => _TambahKamarPageState();
}

class _TambahKamarPageState extends State<TambahKamarPage> {
  final _formKey = GlobalKey<FormState>();
  final _kamarService = KamarService();
  bool _isLoading = false;
  bool _showOptionalPrices = false;

  final _tipeKamarController = TextEditingController();
  final _jumlahUnitController = TextEditingController();
  final _hargaSewaController = TextEditingController();
  final _hargaSewa1Controller = TextEditingController();
  final _hargaSewa2Controller = TextEditingController();
  final _hargaSewa3Controller = TextEditingController();
  final _hargaSewa4Controller = TextEditingController();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _formatToRupiah(String value) {
    if (value.isEmpty) return '';
    value = value.replaceAll(RegExp(r'[^\d]'), '');
    if (value.isEmpty) return '';
    final number = int.parse(value);
    return currencyFormatter.format(number);
  }

  String _parseFromRupiah(String formatted) {
    return formatted.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> _submitKamar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _kamarService.createKamar({
        'tipe_kamar': _tipeKamarController.text,
        'jumlah_unit': int.parse(_jumlahUnitController.text),
        'harga_sewa': int.parse(_parseFromRupiah(_hargaSewaController.text)),
        'harga_sewa1': _hargaSewa1Controller.text.isNotEmpty 
          ? int.parse(_parseFromRupiah(_hargaSewa1Controller.text)) 
          : null,
        'harga_sewa2': _hargaSewa2Controller.text.isNotEmpty 
          ? int.parse(_parseFromRupiah(_hargaSewa2Controller.text)) 
          : null,
        'harga_sewa3': _hargaSewa3Controller.text.isNotEmpty 
          ? int.parse(_parseFromRupiah(_hargaSewa3Controller.text)) 
          : null,
        'harga_sewa4': _hargaSewa4Controller.text.isNotEmpty 
          ? int.parse(_parseFromRupiah(_hargaSewa4Controller.text)) 
          : null,
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan kamar: ${e.toString()}')),
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
        title: Text('Tambah Kamar', style: TextStyle(color: Colors.black)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _tipeKamarController,
                label: 'Tipe Kamar',
                validator: (value) => value!.isEmpty ? 'Tipe kamar harus diisi' : null,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _jumlahUnitController,
                label: 'Jumlah Unit',
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Jumlah unit harus diisi' : null,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _hargaSewaController,
                label: 'Harga Sewa (per bulan)',
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Harga sewa harus diisi' : null,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Harga Sewa Opsional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showOptionalPrices = !_showOptionalPrices;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 172, 101, 51), // Warna yang sama dengan button simpan
                    ),
                    child: Text(_showOptionalPrices ? 'Sembunyikan' : 'Tambah', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              if (_showOptionalPrices) ...[
                SizedBox(height: 8),
                _buildTextField(
                  controller: _hargaSewa1Controller,
                  label: 'Harga Sewa 3 Bulan',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _hargaSewa2Controller,
                  label: 'Harga Sewa 6 Bulan',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _hargaSewa3Controller,
                  label: 'Harga Sewa 1 Tahun',
                  keyboardType: TextInputType.number,
                ),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKamar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A2F1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    bool isPrice = label.toLowerCase().contains('harga');

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Color(0xFFFFE5CC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      onChanged: isPrice ? (value) {
        final cursorPosition = controller.selection;
        final formatted = _formatToRupiah(value);
        controller.text = formatted;
        if (formatted.length >= cursorPosition.start) {
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: formatted.length),
          );
        }
      } : null,
    );
  }

  @override
  void dispose() {
    _tipeKamarController.dispose();
    _jumlahUnitController.dispose();
    _hargaSewaController.dispose();
    _hargaSewa1Controller.dispose();
    _hargaSewa2Controller.dispose();
    _hargaSewa3Controller.dispose();
    _hargaSewa4Controller.dispose();
    super.dispose();
  }
} 