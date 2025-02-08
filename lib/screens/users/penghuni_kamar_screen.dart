import 'package:flutter/material.dart';
import '../../data/services/kamar_service.dart';

class PenghuniKamarScreen extends StatefulWidget {
  @override
  _PenghuniKamarScreenState createState() => _PenghuniKamarScreenState();
}

class _PenghuniKamarScreenState extends State<PenghuniKamarScreen> {
  final KamarService _kamarService = KamarService();
  List<Map<String, dynamic>> _kamarList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKamarData();
  }

  Future<void> _loadKamarData() async {
    try {
      final data = await _kamarService.getAllKamar();
      if (data != null) {
        setState(() {
          _kamarList = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading kamar data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showPenghuniDetail(Map<String, dynamic> kamar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamar ${kamar['nomor_kamar'] ?? '-'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildDetailRow('Nama', kamar['nama_penghuni'] ?? '-'),
                SizedBox(height: 8),
                _buildDetailRow('Asal', kamar['alamat_asal'] ?? '-'),
                SizedBox(height: 8),
                _buildDetailRow('No WA', kamar['nomor_wa'] ?? 'Kosong'),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: Color(0xFF4A2F1C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(' : '),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: Text(
            'Lihat Penghuni Kamar Kos',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFE7B789),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKamarData,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _kamarList.length,
                itemBuilder: (context, index) {
                  final kamar = _kamarList[index];
                  final status = kamar['status'] ?? 'Kosong';
                  final isDihuni = status.toLowerCase() == 'dihuni';
                  final backgroundColor = isDihuni 
                      ? Color(0xFFE7B789)
                      : Colors.grey[300];

                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Material(
                      borderRadius: BorderRadius.circular(8),
                      color: backgroundColor,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isDihuni ? () => _showPenghuniDetail(kamar) : null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Kamar ${kamar['nomor_kamar'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isDihuni ? 'Dihuni' : 'Kosong',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
} 