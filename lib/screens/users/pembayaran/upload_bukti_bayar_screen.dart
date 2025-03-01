import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class UploadBuktiBayarScreen extends StatefulWidget {
  @override
  _UploadBuktiBayarScreenState createState() => _UploadBuktiBayarScreenState();
}

class _UploadBuktiBayarScreenState extends State<UploadBuktiBayarScreen> {
  final PembayaranService _service = PembayaranService();
  final TextEditingController _jumlahController = TextEditingController(); // Add this
  String? _selectedMetode;
  File? _image;
  bool _isLoading = false;
  List<Map<String, dynamic>> _metodePembayaran = [];
  List<Map<String, dynamic>> _hargaSewaOptions = [];
  String? _selectedHargaSewa;

  @override
  void initState() {
    super.initState();
    _loadMetodePembayaran();
    _loadHargaSewaOptions(); // Add this
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final data = await _service.getAllMetodePembayaran();
      print('Loaded data: $data'); // Debug print
      setState(() => _metodePembayaran = data);
    } catch (e) {
      print('Error loading metode pembayaran: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat metode pembayaran')),
      );
    }
  }

  Future<void> _loadHargaSewaOptions() async {
  try {
    setState(() => _isLoading = true);
    final response = await _service.getUserKamarDetail();
    
    if (response.isEmpty) {
      throw Exception('Data kamar tidak ditemukan');
    }

    setState(() {
      _hargaSewaOptions = [];
      
      if (response['unit_kamar'] != null && 
          response['unit_kamar']['kamar'] != null) {
        final kamar = response['unit_kamar']['kamar'];
        
        // Add monthly price
        if (kamar['harga_sewa'] != null) {
          _hargaSewaOptions.add({
            'durasi': '1 Bulan',
            'harga': double.parse(kamar['harga_sewa'].toString()),
          });
        }
        
        // Add other durations
        if (kamar['harga_sewa1'] != null) {
          _hargaSewaOptions.add({
            'durasi': '2 Bulan',
            'harga': double.parse(kamar['harga_sewa1'].toString()),
          });
        }
        
        if (kamar['harga_sewa2'] != null) {
          _hargaSewaOptions.add({
            'durasi': '3 Bulan',
            'harga': double.parse(kamar['harga_sewa2'].toString()),
          });
        }
        
        if (kamar['harga_sewa3'] != null) {
          _hargaSewaOptions.add({
            'durasi': '6 Bulan',
            'harga': double.parse(kamar['harga_sewa3'].toString()),
          });
        }
        
        if (kamar['harga_sewa4'] != null) {
          _hargaSewaOptions.add({
            'durasi': '12 Bulan',
            'harga': double.parse(kamar['harga_sewa4'].toString()),
          });
        }
      }
    });
  } catch (e) {
    print('Error loading harga sewa: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal memuat harga sewa: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _image = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar')),
      );
    }
  }

  Future<void> _uploadBuktiPembayaran() async {
    if (_selectedMetode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih metode pembayaran')),
      );
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih bukti pembayaran')),
      );
      return;
    }

    if (_selectedHargaSewa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih durasi sewa')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Find selected duration option
      final selectedOption = _hargaSewaOptions.firstWhere(
        (option) => option['harga'].toString() == _selectedHargaSewa,
      );

      // Create keterangan from selected duration and price
      final keterangan = 'Pembayaran sewa ${selectedOption['durasi']} - Rp ${NumberFormat('#,###').format(double.parse(_selectedHargaSewa!))}';

      await _service.uploadBuktiPembayaran(
        metodePembayaranId: _selectedMetode!,
        buktiPembayaran: _image!,
        jumlahPembayaran: _selectedHargaSewa!,
        keterangan: keterangan, // Add keterangan parameter
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/verif.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 16),
                Text(
                  'Upload Bukti Pembayaran\nBerhasil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Silahkan tunggu verifikasi\ndari admin',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    Navigator.of(context).pop(); // Kembali ke screen sebelumnya
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A2F1C),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Kembali',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      
      );
        print('Error uploading bukti pembayaran: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Metode Pembayaran: $_metodePembayaran');
    print('Selected Metode: $_selectedMetode');
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Bukti Bayar Sewa'),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih pembayaran melalui',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFFFE5CC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedMetode, // Remove initial value
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Color(0xFFFFE5CC),
                ),
                hint: Text('Pilih metode pembayaran'), // Use hint instead of initial item
                items: _metodePembayaran.map((metode) {
                  return DropdownMenuItem<String>(
                    value: metode['id_metode'].toString(),
                    child: Text(metode['nama']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetode = value;
                  });
                },
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Upload Bukti Transfer',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Color(0xFFFFE5CC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.upload_file,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(height: 8),
            _buildHargaSewaDropdown(),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadBuktiPembayaran,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A2F1C),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHargaSewaDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFE5CC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedHargaSewa,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Pilih Durasi Sewa',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: Color(0xFFFFE5CC),
        ),
        items: _hargaSewaOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option['harga'].toString(),
            child: Text('${option['durasi']} - Rp ${NumberFormat('#,###').format(option['harga'])}'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedHargaSewa = value;
            _jumlahController.text = value ?? '';
          });
        },
      ),
    );
  }
}