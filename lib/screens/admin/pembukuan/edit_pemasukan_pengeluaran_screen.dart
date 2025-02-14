import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';

class EditPemasukanPengeluaranScreen extends StatefulWidget {
  final Map<String, dynamic> transaksi;
  
  const EditPemasukanPengeluaranScreen({
    Key? key,
    required this.transaksi,
  }) : super(key: key);

  @override
  _EditPemasukanPengeluaranScreenState createState() => _EditPemasukanPengeluaranScreenState();
}

class _EditPemasukanPengeluaranScreenState extends State<EditPemasukanPengeluaranScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PemasukanPengeluaranService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  late DateTime _selectedDate;
  String? _selectedKategori;
  late TextEditingController _keteranganController;
  late TextEditingController _jumlahController;
  bool _isLoading = false;
  late bool _isPemasukan;

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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.parse(widget.transaksi['tanggal']);
    _selectedKategori = widget.transaksi['kategori'];
    _keteranganController = TextEditingController(text: widget.transaksi['keterangan']);
    
    // Konversi jumlah ke double terlebih dahulu
    double jumlah = double.parse(widget.transaksi['jumlah'].toString());
    _jumlahController = TextEditingController(
      text: currencyFormatter.format(jumlah),
    );
    _isPemasukan = widget.transaksi['jenis_transaksi'] == 'pemasukan';

    // Log ID transaksi untuk debugging
    print('ID Transaksi: ${widget.transaksi['id']}');
  }

  void _formatCurrency(String value) {
    if (value.isNotEmpty) {
      value = value.replaceAll('Rp ', '').replaceAll('.', '');
      try {
        double number = double.parse(value);
        final formatted = currencyFormatter.format(number);
        _jumlahController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      } catch (e) {
        print('Error formatting currency: $e');
      }
    }
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

  Future<void> _deleteTransaksi() async {
    try {
      // Pastikan ID transaksi tidak null
      if (widget.transaksi['id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID transaksi tidak valid')),
        );
        return;
      }

      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ?? false;

      if (confirm) {
        await _service.delete(widget.transaksi['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateTransaksi() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Pastikan ID transaksi tidak null
        if (widget.transaksi['id'] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ID transaksi tidak valid')),
          );
          return;
        }

        String jumlahStr = _jumlahController.text.replaceAll('Rp ', '').replaceAll('.', '');
        double jumlah = double.parse(jumlahStr);

        await _service.update(
          id: widget.transaksi['id'],
          jenisTransaksi: _isPemasukan ? 'pemasukan' : 'pengeluaran',
          kategori: _selectedKategori!,
          tanggal: _selectedDate,
          jumlah: jumlah,
          keterangan: _keteranganController.text,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui transaksi: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_isPemasukan ? 'Pemasukan' : 'Pengeluaran'}'),
        backgroundColor: Color(0xFFE7B789),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteTransaksi,
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
                onPressed: _isLoading ? null : _updateTransaksi,
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
                        'Perbarui',
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