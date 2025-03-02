import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';
import 'package:proyekkos/screens/admin/pembukuan/tambah_pemasukan_pengeluaran_screen.dart';
import 'package:proyekkos/screens/admin/pembukuan/edit_pemasukan_pengeluaran_screen.dart';
import 'package:proyekkos/screens/admin/pembukuan/kwitansi_pembayaran_screen.dart';
import 'package:proyekkos/widgets/custom_date_range_report.dart';

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
      
      // Filter transaksi untuk tahun berjalan saja
      final filteredTransaksi = transaksi.where((item) {
        final tanggalTransaksi = DateTime.parse(item['tanggal']);
        return tanggalTransaksi.year == now.year;
      }).toList();
      
      // Hitung ulang total pemasukan dan pengeluaran untuk tahun ini
      double totalPemasukan = 0;
      double totalPengeluaran = 0;
      
      for (var item in filteredTransaksi) {
        final jumlah = double.parse(item['jumlah'].toString());
        if (item['jenis_transaksi'] == 'pemasukan') {
          totalPemasukan += jumlah;
        } else {
          totalPengeluaran += jumlah;
        }
      }
      
      setState(() {
        _rekapData = {
          'total_pemasukan': totalPemasukan,
          'total_pengeluaran': totalPengeluaran,
        };
        _transaksi = filteredTransaksi;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
      );
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
    setState(() => _isLoading = true);
    
    try {
      // Reload fresh data first
      await _loadData();
      
      if (jenis.toLowerCase() == 'semua') {
        // Data already reloaded, just update loading state
        setState(() => _isLoading = false);
        return;
      }

      final filteredData = _transaksi.where((item) => 
        item['jenis_transaksi'].toLowerCase() == jenis.toLowerCase()
      ).toList();

      // Recalculate totals for filtered data
      double totalPemasukan = 0;
      double totalPengeluaran = 0;
      
      for (var item in filteredData) {
        final jumlah = double.parse(item['jumlah'].toString());
        if (item['jenis_transaksi'] == 'pemasukan') {
          totalPemasukan += jumlah;
        } else {
          totalPengeluaran += jumlah;
        }
      }

      setState(() {
        _transaksi = filteredData;
        _rekapData = {
          'total_pemasukan': totalPemasukan,
          'total_pengeluaran': totalPengeluaran,
        };
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
        title: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(
            'Pembukuan Keuangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        backgroundColor: Color(0xFFE7B789),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          CustomDateRangeReport(), // Add this
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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'Panduan Penggunaan',
                                          style: TextStyle(
                                            color: Color(0xFF4A2F1C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildInfoSection(
                                                'Menambah Transaksi:',
                                                [
                                                  '1. Tekan tombol + di pojok kanan bawah',
                                                  '2. Pilih jenis transaksi (Pemasukan/Pengeluaran)',
                                                  '3. Pilih kategori transaksi',
                                                  '4. Isi jumlah nominal',
                                                  '5. Tambahkan keterangan jika diperlukan',
                                                  '6. Tekan tombol Simpan',
                                                ],
                                              ),
                                              SizedBox(height: 16),
                                              _buildInfoSection(
                                                'Mengubah Transaksi:',
                                                [
                                                  '1. Tekan item transaksi yang ingin diubah',
                                                  '2. Ubah informasi yang diinginkan',
                                                  '3. Tekan tombol Perbarui',
                                                  'Catatan: Transaksi dari pembayaran tidak dapat diubah',
                                                ],
                                              ),
                                              SizedBox(height: 16),
                                              _buildInfoSection(
                                                'Menghapus Transaksi:',
                                                [
                                                  '1. Tekan item transaksi yang ingin dihapus',
                                                  '2. Tekan icon hapus di pojok kanan atas',
                                                  '3. Konfirmasi penghapusan',
                                                  'Catatan: Transaksi dari pembayaran tidak dapat dihapus',
                                                ],
                                              ),
                                              SizedBox(height: 16),
                                              _buildInfoSection(
                                                'Filter dan Rekap:',
                                                [
                                                  '• Gunakan dropdown filter untuk melihat transaksi berdasarkan periode',
                                                  '• Gunakan kalender untuk melihat transaksi pada tanggal tertentu',
                                                  '• Lihat rekap total pemasukan dan pengeluaran di bagian atas',
                                                  '• Lihat rekap total akan di reset setiap 1 tahun',
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: Text(
                                              'Tutup',
                                              style: TextStyle(color: Color(0xFF4A2F1C)),
                                            ),
                                            onPressed: () => Navigator.of(context).pop(),
                                          ),
                                        ],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        backgroundColor: Color(0xFFFFF8E7),
                                      );
                                    },
                                  );
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
          'Semua',
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
              _filterData(newValue);
            });
          }
        },
      ),
    );
  }

  void _filterData(String filter) async {
    setState(() => _isLoading = true);
    
    try {
      // Reload fresh data first
      await _loadData();
      
      final now = DateTime.now();
      final filteredData = _transaksi.where((item) {
        final tanggal = DateTime.parse(item['tanggal']);
        
        switch(filter) {
          case 'Hari Ini':
            return tanggal.year == now.year && 
                   tanggal.month == now.month && 
                   tanggal.day == now.day;
          case 'Minggu Ini':
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(Duration(days: 6));
            return tanggal.isAfter(startOfWeek.subtract(Duration(days: 1))) && 
                   tanggal.isBefore(endOfWeek.add(Duration(days: 1)));
          case 'Bulan Ini':
            return tanggal.year == now.year && tanggal.month == now.month;
          case 'Tahun Ini':
            return tanggal.year == now.year;
          default: // 'Semua'
            return true;
        }
      }).toList();

      // Recalculate totals for filtered data
      double totalPemasukan = 0;
      double totalPengeluaran = 0;
      
      for (var item in filteredData) {
        final jumlah = double.parse(item['jumlah'].toString());
        if (item['jenis_transaksi'] == 'pemasukan') {
          totalPemasukan += jumlah;
        } else {
          totalPengeluaran += jumlah;
        }
      }

      setState(() {
        _transaksi = filteredData;
        _rekapData = {
          'total_pemasukan': totalPemasukan,
          'total_pengeluaran': totalPengeluaran,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error filtering data: $e');
      setState(() => _isLoading = false);
    }
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
        
        // Check for both Order Menu and Pembayaran Sewa
        final isOrderMenu = transaksi['kategori'] == 'Order Menu';
        final isSewa = transaksi['kategori'] == 'Pembayaran Sewa';
        final isFromPayment = isOrderMenu || isSewa;
        
        return GestureDetector(
          onTap: () async {
            if (isFromPayment) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KwitansiPembayaranScreen(
                    transaksi: {
                      'jumlah_pembayaran': jumlah,
                      'id_pembayaran': transaksi['id_pembayaran']?.toString() ?? '',
                      'tanggal': transaksi['tanggal_pembayaran'] ?? transaksi['tanggal'],
                      'metode_pembayaran': transaksi['metode_pembayaran']?['nama_metode'] ?? 'Tidak diketahui',
                      'keterangan': transaksi['keterangan'] ?? '',
                      'status': transaksi['status_verifikasi'] ?? 'verified',
                      'nama_penyewa': transaksi['penyewa']?['user']?['name'] ?? 'Tidak diketahui',
                      'nomor_kamar': isOrderMenu ? 'Order Menu' : (transaksi['penyewa']?['unit_kamar']?['nomor_kamar'] ?? '-'),
                    },
                  ),
                ),
              );
            } else {
              // Show edit screen for manual transactions
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPemasukanPengeluaranScreen(
                    transaksi: transaksi,
                  ),
                ),
              );
              
              if (result == true) {
                await _loadData();
              }
            }
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Image.asset(
                isIncome 
                    ? isOrderMenu 
                        ? 'assets/images/pesanmakan.png'
                        : 'assets/images/pemasukan.png'
                    : 'assets/images/pengeluaran.png',
                width: 50,
                height: 50,
              ),
              title: Row(
                children: [
                  Text(transaksi['kategori']),
                  if (isFromPayment)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.receipt_long,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaksi['keterangan'] ?? ''),
                  Text(
                    DateFormat('dd MMM yyyy').format(
                      DateTime.parse(transaksi['tanggal_pembayaran'] ?? transaksi['tanggal'])
                    ),
                    style: TextStyle(fontSize: 12),
                  ),
                  if (isFromPayment) ...[
                    Text(
                      'Metode: ${transaksi['metode_pembayaran']?['nama_metode'] ?? 'Tidak diketahui'}',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (!isOrderMenu) ...[
                      Text(
                        'Kamar: ${transaksi['penyewa']?['unit_kamar']?['nomor_kamar'] ?? '-'}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                    Text(
                      'Penyewa: ${transaksi['penyewa']?['user']?['name'] ?? 'Tidak diketahui'}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
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

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A2F1C),
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        )),
      ],
    );
  }
}