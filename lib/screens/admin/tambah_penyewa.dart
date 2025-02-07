import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class TambahPenyewaPage extends StatefulWidget {
  final String nomorKamar;
  final String idUnit;

  TambahPenyewaPage({required this.nomorKamar, required this.idUnit});

  @override
  _TambahPenyewaPageState createState() => _TambahPenyewaPageState();
}

class _TambahPenyewaPageState extends State<TambahPenyewaPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  File? _fotoKtpFile;
  
  // Controllers
  final _namaController = TextEditingController();
  final _asalController = TextEditingController();
  final _tanggalMasukController = TextEditingController();
  final _noHPController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nikController = TextEditingController();
  
  // Durasi dan harga sewa
  int selectedDurasi = 1;
  double selectedHarga = 0.0;
  List<Map<String, dynamic>> durasiOptions = [];

  // Tambahkan variable untuk visibility password
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tanggalMasukController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchKamarDetail();
  }

  Future<void> _fetchKamarDetail() async {
    try {
      setState(() => _isLoading = true);
      
      // Ambil detail kamar dari API
      final response = await PenyewaService().getKamarDetail(widget.idUnit);
      
      setState(() {
        // Reset durasiOptions
        durasiOptions = [];

        // Mapping durasi dan harga
        if (response['harga_bulanan'] != null) {
          durasiOptions.add({
            'durasi': 1,
            'hari': 30,
            'harga': double.parse(response['harga_bulanan'].toString())
          });
        }
        if (response['harga_2_bulan'] != null) {
          durasiOptions.add({
            'durasi': 2,
            'hari': 60,
            'harga': double.parse(response['harga_2_bulan'].toString())
          });
        }
        if (response['harga_3_bulan'] != null) {
          durasiOptions.add({
            'durasi': 3,
            'hari': 90,
            'harga': double.parse(response['harga_3_bulan'].toString())
          });
        }
        if (response['harga_6_bulan'] != null) {
          durasiOptions.add({
            'durasi': 6,
            'hari': 180,
            'harga': double.parse(response['harga_6_bulan'].toString())
          });
        }
          if (response['harga_tahunan'] != null) {
          durasiOptions.add({
            'durasi': 12,
            'hari': 360,
            'harga': double.parse(response['harga_tahunan'].toString())
          });
        }

        // Set nilai default jika ada opsi
        if (durasiOptions.isNotEmpty) {
          selectedDurasi = durasiOptions[0]['durasi'];
          selectedHarga = durasiOptions[0]['harga'];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data kamar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (image != null) {
        setState(() {
          _fotoKtpFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _savePenyewa() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_fotoKtpFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon upload foto KTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final PenyewaService _penyewaService = PenyewaService();
      await _penyewaService.createPenyewa(
        name: _namaController.text,
        email: _emailController.text,
        password: _passwordController.text,
        idUnit: widget.idUnit,
        nik: _nikController.text,
        fotoKtp: _fotoKtpFile!,
        alamatAsal: _asalController.text,
        nomorWa: _noHPController.text,
        tanggalMasuk: _tanggalMasukController.text,
        durasiSewa: selectedDurasi,
        hargaSewa: selectedHarga,
      );

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambahkan penyewa baru'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan penyewa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Tambahkan fungsi validasi email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    // Regex untuk validasi email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Tambahkan fungsi validasi password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    // Tambahkan validasi untuk memastikan password memiliki huruf dan angka
    bool hasLetter = value.contains(RegExp(r'[A-Za-z]'));
    bool hasNumber = value.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasNumber) {
      return 'Password harus mengandung huruf dan angka';
    }
    return null;
  }

  // Tambahkan fungsi validasi nomor HP
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor HP tidak boleh kosong';
    }
    if (!value.startsWith('08')) {
      return 'Nomor HP harus dimulai dengan 08';
    }
    if (value.length < 10 || value.length > 13) {
      return 'Nomor HP harus 10-13 digit';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Tambah Penyewa ${widget.nomorKamar}',
          style: TextStyle(color: Colors.black, fontSize: 18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto KTP
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _fotoKtpFile != null
                      ? Image.file(_fotoKtpFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50),
                            Text('Pilih Foto KTP'),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Penyewa',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Durasi Sewa:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedDurasi,
                        isExpanded: true,
                        items: durasiOptions.map((option) {
                          return DropdownMenuItem<int>(
                            value: option['durasi'],
                            child: Text(
                              '${option['durasi']} bulan - Rp ${NumberFormat('#,###').format(option['harga'])}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDurasi = value!;
                            var option = durasiOptions.firstWhere(
                              (opt) => opt['durasi'] == value
                            );
                            selectedHarga = option['harga'];
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tanggal Keluar:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy').format(
                      DateTime.now().add(
                        Duration(days: selectedDurasi * 30)
                      )
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noHPController,
                decoration: InputDecoration(
                  labelText: 'No HP',
                  border: OutlineInputBorder(),
                  hintText: '08xxxxxxxxxx',
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nikController,
                decoration: InputDecoration(
                  labelText: 'NIK',
                  border: OutlineInputBorder(),
                  hintText: '16 digit NIK',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIK tidak boleh kosong';
                  }
                  if (value.length != 16) {
                    return 'NIK harus 16 digit';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'contoh@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  hintText: 'Minimal 8 karakter',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible 
                        ? Icons.visibility 
                        : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: _validatePassword,
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePenyewa,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Simpan'),
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
    _noHPController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nikController.dispose();
    super.dispose();
  }
} 