import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';
import 'package:proyekkos/screens/admin/pembukuan/tambah_pemasukan_pengeluaran_screen.dart';
import 'package:proyekkos/screens/admin/pembukuan/edit_pemasukan_pengeluaran_screen.dart';

class PemasukanPengeluaranScreen extends StatefulWidget {
  @override
  _PemasukanPengeluaranScreenState createState() => _PemasukanPengeluaranScreenState();
}

class _PemasukanPengeluaranScreenState extends State<PemasukanPengeluaranScreen> {
  final PemasukanPengeluaranService _service = PemasukanPengeluaranService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID', 
    symbol: 'Rp ', 
    decimalDigits: 0
  );
  
  String _selectedFilter = 'Bulan Ini'; // Default filter
  String _selectedJenisTransaksi = 'Semua';
  List<Map<String, dynamic>> _transaksi = [];
  Map<String, dynamic> _rekapData = {};
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now(); // Tambahkan ini

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final rekap = await _service.getRekapBulanan(now.month, now.year);
      final transaksi = await _service.getAllTransaksi();
      
      setState(() {
        _rekapData = rekap;
        _transaksi = transaksi;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      // Pastikan initialDate tidak melebihi lastDate
      DateTime now = DateTime.now();
      DateTime lastDate = DateTime(now.year + 1, 12, 31); // Tahun sekarang + 1
      DateTime initialDate = _selectedDate.isAfter(lastDate) ? lastDate : _selectedDate;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2020),
        lastDate: lastDate, // Gunakan lastDate yang sudah dihitung
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
        setState(() {
          _selectedDate = picked;
        });
        
        // Load data untuk tanggal yang dipilih
        setState(() => _isLoading = true);
        try {
          final data = await _service.getTransaksiByDate(picked);
          setState(() {
            if (data['transaksi'] != null) {
              _transaksi = List<Map<String, dynamic>>.from(data['transaksi']);
            } else {
              _transaksi = [];
            }
            _rekapData = {
              'total_pemasukan': data['total_pemasukan'] ?? 0,
              'total_pengeluaran': data['total_pengeluaran'] ?? 0,
            };
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error in _selectDate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat memilih tanggal')),
      );
    }
  }

  Future<void> _loadTransaksiByJenis(String jenis) async {
    if (jenis == 'semua') {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final transaksi = await _service.getTransaksiByJenis(jenis);
      setState(() {
        _transaksi = transaksi;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembukuan Keuangan'),
        backgroundColor: Color(0xFFE7B789),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hasil Rekap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                            
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Show info dialog
                                },
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      _buildRekapCard(),
                      SizedBox(height: 16),
                        Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                            'Pilih Kategori',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                            Container(
                                    width: 150,
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedJenisTransaksi,
                                      isExpanded: true,
                                      underline: SizedBox(),
                                      items: [
                                        'Semua',
                                        'Pemasukan',
                                        'Pengeluaran',
                                      ].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedJenisTransaksi = newValue;
                                            _loadTransaksiByJenis(newValue.toLowerCase());
                                          });
                                        }
                                      },
                                    ),
                                  ),
                          ],
                        ),
                        SizedBox(height: 16),
                      Text('Filter',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                      _buildFilterDropdown(),
                      SizedBox(height: 16),
                      _transaksi.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Data transaksi masih belum tersedia',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : _buildTransaksiList(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahPemasukanPengeluaranScreen(
                isPemasukan: true, // Default ke pemasukan
              ),
            ),
          ).then((value) {
            if (value == true) {
              _loadData(); // Refresh data setelah menambah
            }
          });
        },
        child: Image.asset(
          'assets/images/add_icon.png',
          width: 100,
          height: 100,
        ),
      ),
    );
  }

  Widget _buildRekapCard() {
    // Pastikan konversi ke double untuk semua nilai numerik
    final totalPemasukan = double.parse((_rekapData['total_pemasukan'] ?? 0).toString());
    final totalPengeluaran = double.parse((_rekapData['total_pengeluaran'] ?? 0).toString());
    final total = totalPemasukan - totalPengeluaran;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemasukan',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      currencyFormatter.format(totalPemasukan),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Pengeluaran',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      currencyFormatter.format(totalPengeluaran),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      currencyFormatter.format(total),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        isExpanded: true,
        underline: SizedBox(),
        items: [
          'Hari Ini',
          'Minggu Ini',
          'Bulan Ini',
          'Tahun Ini',
        ].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedFilter = newValue;
              // TODO: Implement filter logic
            });
          }
        },
      ),
    );
  }

  Widget _buildTransaksiList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _transaksi.length,
      itemBuilder: (context, index) {
        final transaksi = _transaksi[index];
        final isIncome = transaksi['jenis_transaksi'] == 'pemasukan';
        final jumlah = double.parse(transaksi['jumlah'].toString());
        
        // Cek apakah transaksi berasal dari pembayaran sewa
        final isFromPayment = transaksi['keterangan']?.toString().contains('[ID Penyewa:') ?? false;
        
        return GestureDetector(
          onTap: () async {
            if (!isFromPayment) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPemasukanPengeluaranScreen(
                    transaksi: transaksi,
                  ),
                ),
              );
              
              if (result != null && result == true) {
                await _loadData();
              }
            }
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Image.asset(
                isIncome ? 'assets/images/pemasukan.png' : 'assets/images/pengeluaran.png',
                width: 50,
                height: 50,
              ),
              title: Text(transaksi['kategori']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaksi['keterangan'] ?? ''),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.parse(transaksi['tanggal'])),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Text(
                currencyFormatter.format(jumlah),
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 