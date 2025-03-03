import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/auth_service.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';
import 'package:proyekkos/widgets/custom_info_dialog.dart';


class VerifikasiPenyewaScreen extends StatefulWidget {
  @override
  _VerifikasiPenyewaScreenState createState() => _VerifikasiPenyewaScreenState();
}

class _VerifikasiPenyewaScreenState extends State<VerifikasiPenyewaScreen> {
  final AuthService _authService = AuthService();
  final PemasukanPengeluaranService _pemasukanService = PemasukanPengeluaranService();

  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.getUsersByRole('user');
      setState(() {
        _pendingUsers = users.where((user) => 
          user['status_verifikasi'] == 'pending' || 
          user['status_verifikasi'] == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        _pendingUsers = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
      );
    }
  }

  Future<Map<String, dynamic>?> _showVerifikasiDialog(Map<String, dynamic> user) async {
    DateTime selectedDate = DateTime.now();
    int selectedDurasi = 1; // Default 1 bulan
    double selectedHarga = 0.0;
    int selectedHari = 30; // Default 30 hari
    
    List<Map<String, dynamic>> durasiOptions = [];
    
    final unitKamar = user['penyewa']?['unit_kamar'];
    final kamar = unitKamar?['kamar'];
    
    // Perbaikan mapping durasi dan harga
    if (kamar != null) {
      if (kamar['harga_sewa'] != null) {
        durasiOptions.add({
          'durasi': 1,  // 1 bulan
          'hari': 30,
          'harga': double.parse(kamar['harga_sewa'].toString())
        });
      }
      if (kamar['harga_sewa1'] != null) {
        durasiOptions.add({
          'durasi': 2,  // 2 bulan
          'hari': 60,
          'harga': double.parse(kamar['harga_sewa1'].toString())
        });
      }
      if (kamar['harga_sewa2'] != null) {
        durasiOptions.add({
          'durasi': 3,  // 3 bulan
          'hari': 90,
          'harga': double.parse(kamar['harga_sewa2'].toString())
        });
      }
      if (kamar['harga_sewa3'] != null) {
        durasiOptions.add({
          'durasi': 6, // 6 bulan
          'hari': 180,
          'harga': double.parse(kamar['harga_sewa3'].toString())
        });
      }
      if (kamar['harga_sewa4'] != null) {
        durasiOptions.add({
          'durasi': 12, // 12 bulan
          'hari': 360,
          'harga': double.parse(kamar['harga_sewa4'].toString())
        });
      }
    }

    if (durasiOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data harga kamar tidak tersedia')),
      );
      return null;
    }

    selectedHarga = durasiOptions[0]['harga'] ?? 0.0;
    selectedDurasi = durasiOptions[0]['durasi'] ?? 1;
    selectedHari = durasiOptions[0]['hari'] ?? 30;

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Verifikasi Penyewa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pilih Tanggal Masuk:'),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE7B789),
                  ),
                  child: Text(
                    DateFormat('dd-MM-yyyy').format(selectedDate),
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                SizedBox(height: 16),
                Text('Pilih Durasi Sewa:'),
                DropdownButton<int>(
                  value: selectedDurasi,
                  items: durasiOptions.map((option) {
                    return DropdownMenuItem<int>(
                      value: option['durasi'],
                      child: Text('${option['durasi']} bulan - Rp ${NumberFormat('#,###').format(option['harga'])}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDurasi = value!;
                      var option = durasiOptions.firstWhere((opt) => opt['durasi'] == value);
                      selectedHarga = option['harga'];
                      selectedHari = option['hari'];
                    });
                  },
                ),
                SizedBox(height: 16),
                Text('Tanggal Keluar:'),
                Text(
                  DateFormat('dd-MM-yyyy').format(
                    selectedDate.add(Duration(days: selectedHari))
                  ),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.pop(context, null), // Return null if cancelled
            ),
            TextButton(
              child: Text('Verifikasi'),
              onPressed: () {
                // Return selected values
                Navigator.pop(context, {
                  'selectedDate': selectedDate,
                  'selectedDurasi': selectedDurasi,
                  'selectedHarga': selectedHarga,
                  'selectedHari': selectedHari
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTolakDialog(Map<String, dynamic> user) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Penolakan'),
        content: Text('Apakah Anda yakin ingin menolak verifikasi penyewa ini?'),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Tolak', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(context);
              await _handleTolak(user);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerifikasi(Map<String, dynamic> user) async {
  // Simpan verifikasi dialog ke dalam variabel untuk mendapatkan nilai yang diinput
  Map<String, dynamic>? dialogResult = await _showVerifikasiDialog(user);
  
  // Jika dialog dibatalkan, keluar dari fungsi
  if (dialogResult == null) return;
  
  // Ambil nilai dari dialog
  final selectedDate = dialogResult['selectedDate'] as DateTime;
  final selectedDurasi = dialogResult['selectedDurasi'] as int;
  final selectedHarga = dialogResult['selectedHarga'] as double;
  final selectedHari = dialogResult['selectedHari'] as int;
  
  try {
    // 1. Verifikasi user terlebih dahulu
    final response = await _authService.verifikasiUser(
      user['id_user'],
      'disetujui',
      selectedDate,
      selectedDurasi,
      selectedHarga,
    );
    
    // 2. Tambahkan transaksi pembayaran sewa ke database
    final idPenyewa = user['penyewa']?['id_penyewa'];
    final nomorKamar = user['penyewa']?['unit_kamar']?['nomor_kamar'] ?? 'Tidak diketahui';
    final namaPenyewa = user['name'] ?? 'Tidak diketahui';
    
    if (idPenyewa != null) {
      // Format keterangan sama persis seperti di tambah_penyewa.dart
      final keterangan = 'Pembayaran sewa kamar ${nomorKamar} - ${namaPenyewa} (${selectedDurasi} bulan)';
      
      // Buat transaksi pemasukan dengan parameter yang sama persis
      await _pemasukanService.create(
        jenisTransaksi: 'pemasukan',
        kategori: 'Pembayaran Sewa',
        tanggal: selectedDate,
        jumlah: selectedHarga,
        keterangan: keterangan,
        idPenyewa: idPenyewa,
        metodePembayaran: 'Dibayar',
        idUser: user['id_user'],
      );
    }
    
    await _fetchPendingUsers();
    
    // Tampilkan dialog konfirmasi berhasil
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verifikasi Berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 16),
              Text('Penyewa berhasil diverifikasi'),
              Text('Pembayaran sewa telah dicatat dalam pembukuan'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil memverifikasi penyewa'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print('Error verifikasi: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjadi kesalahan: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _handleTolak(Map<String, dynamic> user) async {
    try {
      final response = await _authService.verifikasiUser(
        user['id_user'],
        'ditolak',
        null,
        null,
        null  // Set null for harga_sewa too
      );

      if (response['status'] == true) {
        await _fetchPendingUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menolak penyewa'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Gagal menolak penyewa');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: Color(0xFFE7B789),
        title: Text(
          'List Verifikasi Data Penyewa',
          style: TextStyle(color: Colors.black, fontSize: 20),
          
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CustomInfoDialog(
                    title: 'Informasi',
                    message: 'Halaman ini menampilkan daftar penyewa yang perlu diverifikasi',
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pendingUsers.isEmpty
              ? Center(
                  child: Text('Tidak ada data penyewa yang perlu diverifikasi'),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];
                    // Null check untuk data penyewa
                    
                  
                    return Card(
                      color: Color(0xFFFFE5CE),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${user['penyewa']['unit_kamar']['nomor_kamar'] ?? 'Tidak tersedia'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Verifikasi Akun Penyewa',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[300],
                                  child: Icon(Icons.person, size: 40),
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama: ${user['name'] ?? 'Tidak tersedia'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'No HP: ${user['penyewa']['nomor_wa'] ?? 'Tidak tersedia'}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: Size(120, 40),
                                  ),
                                  onPressed: () => _showTolakDialog(user),
                                  child: Text('Tolak'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize: Size(120, 40),
                                  ),
                                  onPressed: () => _handleVerifikasi(user),
                                  child: Text('Verifikasi'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}