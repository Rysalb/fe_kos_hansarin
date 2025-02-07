import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:proyekkos/screens/admin/verifikasi_penyewa.dart';
import 'package:proyekkos/screens/admin/detail_penyewa.dart';
import 'package:proyekkos/screens/admin/tambah_penyewa.dart';

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
        title: Text(
          'Kelola Identitas Penyewa',
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
                                child: Text('Tambah Data'),
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
                                Text('Nama: ${penyewa['user']['name']}'),
                                Text('Sisa: ${_calculateSisaHari(penyewa['tanggal_keluar'], penyewa['durasi_sewa'])} hari'),
                                Text('Status: ${penyewa['status_penyewa']}'),
                              ],
                            ),
                      trailing: Text(
                        isKosong ? 'Kosong' : 'Dihuni',
                        style: TextStyle(
                          color: isKosong ? Colors.red : Colors.green,
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
} 