import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:proyekkos/screens/admin/kelola_penyewa/verifikasi_penyewa.dart';
import 'package:proyekkos/screens/admin/kelola_penyewa/detail_penyewa.dart';
import 'package:proyekkos/screens/admin/kelola_penyewa/tambah_penyewa.dart';

class KelolaPenyewaPage extends StatefulWidget {
  @override
  _KelolaPenyewaPageState createState() => _KelolaPenyewaPageState();
}

class _KelolaPenyewaPageState extends State<KelolaPenyewaPage> {
  final PenyewaService _penyewaService = PenyewaService();
  List<Map<String, dynamic>> _unitList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUnitData();
  }

  Future<void> _fetchUnitData() async {
    setState(() => _isLoading = true);
    try {
      final unitData = await _penyewaService.getAllUnits();
      setState(() {
        _unitList = List<Map<String, dynamic>>.from(unitData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching unit data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Kelola Identitas Penyewa',
            style: TextStyle(
              color: Colors.black, 
              fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive font size
              fontWeight: FontWeight.bold,
            ),
          ),
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
                            'Status Kamar:',
                            [
                              '• Kosong: Kamar belum ada penyewa',
                              '• Dihuni: Kamar sudah ada penyewa aktif',
                              '• Warna abu: Menandakan kamar kosong',
                              '• Warna cream: Menandakan kamar dihuni',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Menambah Penyewa Baru:',
                            [
                              '1. Pilih kamar dengan status "Kosong"',
                              '2. Tekan tombol "Tambah Data"',
                              '3. Isi formulir data penyewa',
                              '4. Upload foto KTP',
                              '5. Simpan data penyewa',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Melihat Detail Penyewa:',
                            [
                              '1. Pilih kamar dengan status "Dihuni"',
                              '2. Tekan card untuk melihat detail',
                              '3. Lihat informasi lengkap penyewa',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Verifikasi Penyewa:',
                            [
                              '1. Tekan icon identitas di pojok kanan atas',
                              '2. Pilih penyewa yang akan diverifikasi',
                              '3. Cek kelengkapan data dan dokumen',
                              '4. Verifikasi atau tolak pendaftaran',
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
          ),
          IconButton(
            icon: Image.asset('assets/images/dashboard_icon/identitas_penyewa.png', width: 50, height: 50),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifikasiPenyewaScreen(),
                ),
              ).then((result) {
                if(result == true){
                  _fetchUnitData();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _unitList.length,
              itemBuilder: (context, index) {
                final unit = _unitList[index];
                final penyewa = unit['penyewa'];
                final bool isKosong = penyewa == null || 
                    (penyewa != null && penyewa['status_penyewa'] == 'tidak_aktif');

                return Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isKosong ? Colors.grey[300] : Color(0xFFFFE5CC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                      title: Text(
                        '${unit['nomor_kamar']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive font size
                        ),
                      ),
                      subtitle: isKosong
                          ? Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TambahPenyewaPage(
                                        nomorKamar: unit['nomor_kamar'],
                                        idUnit: unit['id_unit'].toString(),
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _fetchUnitData(); // Refresh data setelah menambah penyewa
                                    }
                                  });
                                },
                                child: Text(
                                  'Tambah Data',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive font size
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 0, 0, 0),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 10.0,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nama: ${penyewa['user']['name']}',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive font size
                                  ),
                                ),
                                Text(
                                  'Sisa: ${_calculateSisaHari(penyewa['tanggal_keluar'], penyewa['durasi_sewa'])} hari',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                  ),
                                ),
                                Text(
                                  'Status: ${penyewa['status_penyewa']}',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                  ),
                                ),
                              ],
                            ),
                      trailing: Text(
                        isKosong ? 'Kosong' : 'Dihuni',
                        style: TextStyle(
                          color: isKosong ? Colors.red : Colors.green,
                          fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive font size
                        ),
                      ),
                      onTap: isKosong
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailPenyewaPage(
                                    idPenyewa: penyewa['id_penyewa'],
                                  ),
                                ),
                              ).then((_) => _fetchUnitData());
                            },
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _calculateSisaHari(String tanggalKeluar, int durasiSewa) {
    final keluar = DateTime.parse(tanggalKeluar);
    final sekarang = DateTime.now();
    final selisih = keluar.difference(sekarang).inDays;
    // Menghitung sisa hari berdasarkan durasi sewa
    return (selisih < 0) ? 'Sewa telah berakhir' : selisih.toString();
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive title
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
              fontSize: MediaQuery.of(context).size.width * 0.035, // Responsive items
              color: Colors.black87,
            ),
          ),
        )),
      ],
    );
  }
}