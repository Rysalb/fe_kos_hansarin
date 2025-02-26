import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';

class TambahPemasukanPengeluaranScreen extends StatefulWidget {
  final bool isPemasukan; // true untuk pemasukan, false untuk pengeluaran
  
  const TambahPemasukanPengeluaranScreen({
    Key? key, 
    this.isPemasukan = true,
  }) : super(key: key);

  @override
  _TambahPemasukanPengeluaranScreenState createState() => _TambahPemasukanPengeluaranScreenState();
}

class _TambahPemasukanPengeluaranScreenState extends State<TambahPemasukanPengeluaranScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PemasukanPengeluaranService();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedKategori;
  String? _selectedMetodePembayaran = 'Cash'; // Set default method
  final _keteranganController = TextEditingController();
  final _jumlahController = TextEditingController();
  bool _isLoading = false;
  bool _isPemasukan = true;

  // Add new variables
  List<Map<String, dynamic>> _penyewaList = [];
  Map<String, dynamic>? _selectedPenyewa;
  final _penyewaService = PenyewaService();

  // Daftar kategori sesuai jenis transaksi
  final List<String> _kategoriPemasukan = [
    'Pembayaran Sewa',
    'Denda',
    'Lainnya'
  ];
  
  final List<String> _kategoriPengeluaran = [
    'Pembayaran Listrik',
    'Pembayaran Air',
    'Maintenance',
    'Lainnya'
  ];

  final List<String> _metodePembayaran = [
    'Cash',
    'Transfer Bank',
    'E-Wallet',
    'Pembayaran Awal'
  ];

  @override
  void initState() {
    super.initState();
    _isPemasukan = widget.isPemasukan;
    _loadPenyewa();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      DateTime now = DateTime.now();
      DateTime lastDate = DateTime(now.year + 1, 12, 31);
      DateTime initialDate = _selectedDate.isAfter(lastDate) ? lastDate : _selectedDate;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2020),
        lastDate: lastDate,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFFE7B789),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() => _selectedDate = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat memilih tanggal')),
      );
    }
  }

  // Update _loadPenyewa method
  Future<void> _loadPenyewa() async {
    try {
      final response = await _penyewaService.getAllPenyewa();
      setState(() {
        _penyewaList = List<Map<String, dynamic>>.from(response); // Remove ['data'] access
      });
    } catch (e) {
      print('Error loading penyewa: $e');
    }
  }

  // Add penyewa dropdown widget
  Widget _buildPenyewaField() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedPenyewa,
      decoration: InputDecoration(
        labelText: 'Pilih Penyewa',
        border: OutlineInputBorder(),
      ),
      items: _penyewaList.map((penyewa) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: penyewa,
          child: Text('${penyewa['user']['name']} - Kamar ${penyewa['unit_kamar']['nomor_kamar']}'),
        );
      }).toList(),
      onChanged: (Map<String, dynamic>? newValue) {
        setState(() => _selectedPenyewa = newValue);
      },
      validator: (value) {
        if (_selectedKategori == 'Pembayaran Sewa' && value == null) {
          return 'Penyewa harus dipilih';
        }
        return null;
      },
    );
  }

  // Update _submitForm method
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String jumlahStr = _jumlahController.text.replaceAll('Rp ', '').replaceAll('.', '');
        double jumlah = double.parse(jumlahStr);

        // Base keterangan
        String keterangan = _keteranganController.text;
        
        if (_selectedKategori == 'Pembayaran Sewa' && _selectedPenyewa != null) {
          keterangan = 'Pembayaran sewa kamar ${_selectedPenyewa!['unit_kamar']['nomor_kamar']} - '
                      '${_selectedPenyewa!['user']['name']} '
                      '[Metode: ${_selectedMetodePembayaran}]';
          
          // Create pembayaran record
          await _service.create(
            jenisTransaksi: _isPemasukan ? 'pemasukan' : 'pengeluaran',
            kategori: _selectedKategori!,
            tanggal: _selectedDate,
            jumlah: jumlah,
            keterangan: keterangan,
            idPenyewa: int.parse(_selectedPenyewa!['id_penyewa'].toString()), // Convert to int
            metodePembayaran: _selectedMetodePembayaran,
            idUser: int.parse(_selectedPenyewa!['user']['id_user'].toString()), // Add user id
          );
        } else {
          // Regular transaction without payment record
          await _service.create(
            jenisTransaksi: _isPemasukan ? 'pemasukan' : 'pengeluaran',
            kategori: _selectedKategori!,
            tanggal: _selectedDate,
            jumlah: jumlah,
            keterangan: keterangan,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil menyimpan transaksi')),
        );
        
        Navigator.pop(context, true);
      } catch (e) {
        print('Error submitting form: $e'); // Untuk debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Tambahkan method untuk format currency
  void _formatCurrency(String value) {
    if (value.isNotEmpty) {
      value = value.replaceAll('Rp ', '').replaceAll('.', '');
      double number = double.parse(value);
      final formatted = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
      _jumlahController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Widget _buildMetodePembayaranField() {
    return DropdownButtonFormField<String>(
      value: _selectedMetodePembayaran,
      decoration: InputDecoration(
        labelText: 'Metode Pembayaran',
        border: OutlineInputBorder(),
      ),
      items: _metodePembayaran.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() => _selectedMetodePembayaran = newValue);
      },
      validator: (value) {
        if (_selectedKategori == 'Pembayaran Sewa' && (value == null || value.isEmpty)) {
          return 'Metode pembayaran harus dipilih';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPemasukan ? 'Tambah Pemasukan' : 'Tambah Pengeluaran'),
        backgroundColor: Color(0xFFE7B789),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz), // Ganti dengan asset icon switch
            onPressed: () {
              setState(() => _isPemasukan = !_isPemasukan);
              _selectedKategori = null; // Reset kategori saat switch
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tanggal Field
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tanggal harus diisi';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Kategori Dropdown
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: InputDecoration(
                  labelText: 'Pilih Kategori',
                  border: OutlineInputBorder(),
                ),
                items: (_isPemasukan ? _kategoriPemasukan : _kategoriPengeluaran)
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedKategori = newValue);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori harus dipilih';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Add penyewa dropdown before metode pembayaran if kategori is Pembayaran Sewa
              if (_selectedKategori == 'Pembayaran Sewa') ...[
                _buildPenyewaField(),
                SizedBox(height: 16),
                _buildMetodePembayaranField(),
                SizedBox(height: 16),
              ],

              // Keterangan Field
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Keterangan harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Jumlah Field
              TextFormField(
                controller: _jumlahController,
                decoration: InputDecoration(
                  labelText: _isPemasukan ? 'Jumlah Pemasukan' : 'Jumlah Pengeluaran',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: _formatCurrency,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah harus diisi';
                  }
                  try {
                    String numStr = value.replaceAll('Rp ', '').replaceAll('.', '');
                    double.parse(numStr);
                    return null;
                  } catch (e) {
                    return 'Format jumlah tidak valid';
                  }
                },
              ),
              SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A2F1C),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
            ],
          ),
        ),
      ),
    );
  }
}