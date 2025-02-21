import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final PenyewaService _service = PenyewaService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _unitList = [];

  @override
  void initState() {
    super.initState();
    _loadUnitData();
  }

  Future<void> _loadUnitData() async {
    try {
      final data = await _service.getAllUnits();
      if (data != null) {
      setState(() {
        _unitList = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kamar')),
      );
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final whatsappUrl = "https://wa.me/$phoneNumber";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }

  void _showEmptyRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          'Kamar ini masih belum dihuni',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(color: Color(0xFF4A2F1C)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'List Nomor WhatsApp Penghuni Kos SidoRame12',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _unitList.length,
                    itemBuilder: (context, index) {
                      final unit = _unitList[index];
                      final penyewa = unit['penyewa'];
                      final bool isDihuni = unit['status'] == 'dihuni';
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            if (isDihuni && penyewa != null) {
                              _launchWhatsApp(penyewa['nomor_wa']);
                            } else {
                              _showEmptyRoomDialog();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDihuni 
                                ? Color(0xFFFFE5CC) 
                                : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kamar ${unit['nomor_kamar']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isDihuni && penyewa != null) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Penghuni: ${penyewa['user']['name'] ?? 'Tidak ada'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/dashboard_icon/wa.png',
                                  width: 24,
                                  height: 24,
                                  color: isDihuni ? null : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}