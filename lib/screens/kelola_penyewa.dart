import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/verifikasi_penyewa.dart';

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
              );
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
                                  // Navigasi ke halaman tambah penyewa
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
                                Text('Sisa: ${_calculateSisaHari(penyewa['tanggal_keluar'])} hari'),
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

  String _calculateSisaHari(String tanggalKeluar) {
    final keluar = DateTime.parse(tanggalKeluar);
    final sekarang = DateTime.now();
    final selisih = keluar.difference(sekarang).inDays;
    return selisih.toString();
  }
}

class DetailPenyewaPage extends StatefulWidget {
  final int idPenyewa;

  DetailPenyewaPage({required this.idPenyewa});

  @override
  _DetailPenyewaPageState createState() => _DetailPenyewaPageState();
}

class _DetailPenyewaPageState extends State<DetailPenyewaPage> {
  final PenyewaService _penyewaService = PenyewaService();
  Map<String, dynamic>? _penyewaDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPenyewaDetail();
  }

  Future<void> _fetchPenyewaDetail() async {
    try {
      final detail = await _penyewaService.getPenyewaById(widget.idPenyewa);
      setState(() {
        _penyewaDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching penyewa detail: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text('Detail Penyewa', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detail penyewa akan ditampilkan di sini
                  _buildDetailCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard() {
    if (_penyewaDetail == null) return SizedBox();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Penyewa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Nama', _penyewaDetail!['user']['name']),
            _buildInfoRow('NIK', _penyewaDetail!['nik']),
            _buildInfoRow('Alamat Asal', _penyewaDetail!['alamat_asal']),
            _buildInfoRow('Nomor WA', _penyewaDetail!['nomor_wa']),
            _buildInfoRow('Tanggal Masuk', DateFormat('dd MMMM yyyy').format(DateTime.parse(_penyewaDetail!['tanggal_masuk']))),
            _buildInfoRow('Tanggal Keluar', DateFormat('dd MMMM yyyy').format(DateTime.parse(_penyewaDetail!['tanggal_keluar']))),
            _buildInfoRow('Status', _penyewaDetail!['status_penyewa']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 