import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/kamar_service.dart';
import 'package:intl/intl.dart';

class UbahKamarPage extends StatefulWidget {
  final Map<String, dynamic> kamar;

  UbahKamarPage({required this.kamar});

  @override
  _UbahKamarPageState createState() => _UbahKamarPageState();
}

class _UbahKamarPageState extends State<UbahKamarPage> {
  final _formKey = GlobalKey<FormState>();
  final KamarService _kamarService = KamarService();
  
  late TextEditingController _tipeKamarController;
  late TextEditingController _jumlahUnitController;
  late TextEditingController _hargaSewa1Controller;
  late TextEditingController _hargaSewa2Controller;
  late TextEditingController _hargaSewa3Controller;
  late TextEditingController _hargaSewa4Controller;
  late TextEditingController _hargaSewa5Controller;

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

  @override
  void initState() {
    super.initState();
    _tipeKamarController = TextEditingController(text: widget.kamar['tipe_kamar']);
    _jumlahUnitController = TextEditingController(text: widget.kamar['unit_kamar'].length.toString());
    _hargaSewa1Controller = TextEditingController(
      text: _formatToRupiah(widget.kamar['harga_sewa'].toString())
    );
    _hargaSewa2Controller = TextEditingController(
      text: widget.kamar['harga_sewa1'] != null 
        ? _formatToRupiah(widget.kamar['harga_sewa1'].toString()) 
        : ''
    );
    _hargaSewa3Controller = TextEditingController(
      text: widget.kamar['harga_sewa2'] != null 
        ? _formatToRupiah(widget.kamar['harga_sewa2'].toString()) 
        : ''
    );
    _hargaSewa4Controller = TextEditingController(
      text: widget.kamar['harga_sewa3'] != null 
        ? _formatToRupiah(widget.kamar['harga_sewa3'].toString()) 
        : ''
    );
    _hargaSewa5Controller = TextEditingController(
      text: widget.kamar['harga_sewa4'] != null 
        ? _formatToRupiah(widget.kamar['harga_sewa4'].toString()) 
        : ''
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Ubah Tipe Kamar',
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
              // Implementasi info button
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tipeKamarController,
                decoration: InputDecoration(
                  labelText: 'Tipe Kamar',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Tipe kamar harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _jumlahUnitController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Unit',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Jumlah unit harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Harga Sewa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildHargaSewaField('1 Bulan', _hargaSewa1Controller),
              SizedBox(height: 8),
              _buildHargaSewaField('2 Bulan', _hargaSewa2Controller),
              SizedBox(height: 8),
              _buildHargaSewaField('3 Bulan', _hargaSewa3Controller),
              SizedBox(height: 8),
              _buildHargaSewaField('6 Bulan', _hargaSewa4Controller),
              SizedBox(height: 8),
              _buildHargaSewaField('1 Tahun', _hargaSewa5Controller),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateKamar,
                child: Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE7B789),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHargaSewaField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final cursorPosition = controller.selection;
        final formatted = _formatToRupiah(value);
        controller.text = formatted;
        if (formatted.length >= cursorPosition.start) {
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: formatted.length),
          );
        }
      },
    );
  }

  Future<void> _updateKamar() async {
    if (_formKey.currentState!.validate()) {
      try {
        final kamarData = {
          'tipe_kamar': _tipeKamarController.text,
          'jumlah_unit': int.parse(_jumlahUnitController.text),
          'harga_sewa': int.parse(_parseFromRupiah(_hargaSewa1Controller.text)),
          'harga_sewa1': _hargaSewa2Controller.text.isNotEmpty 
            ? int.parse(_parseFromRupiah(_hargaSewa2Controller.text)) 
            : null,
          'harga_sewa2': _hargaSewa3Controller.text.isNotEmpty 
            ? int.parse(_parseFromRupiah(_hargaSewa3Controller.text)) 
            : null,
          'harga_sewa3': _hargaSewa4Controller.text.isNotEmpty 
            ? int.parse(_parseFromRupiah(_hargaSewa4Controller.text)) 
            : null,
          'harga_sewa4': _hargaSewa5Controller.text.isNotEmpty 
            ? int.parse(_parseFromRupiah(_hargaSewa5Controller.text)) 
            : null,
        };

        print('Sending data: $kamarData');

        final success = await _kamarService.updateKamar(widget.kamar['id_kamar'], kamarData);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kamar berhasil diupdate')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengupdate kamar: Server error')),
          );
        }
      } catch (e) {
        print('Error updating kamar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupdate kamar: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tipeKamarController.dispose();
    _jumlahUnitController.dispose();
    _hargaSewa1Controller.dispose();
    _hargaSewa2Controller.dispose();
    _hargaSewa3Controller.dispose();
    _hargaSewa4Controller.dispose();
    _hargaSewa5Controller.dispose();
    super.dispose();
  }
} 