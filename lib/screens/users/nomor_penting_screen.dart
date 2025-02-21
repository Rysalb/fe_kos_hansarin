import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyekkos/data/services/nomor_penting_service.dart';

class NomorPentingScreen extends StatefulWidget {
  @override
  _NomorPentingScreenState createState() => _NomorPentingScreenState();
}

class _NomorPentingScreenState extends State<NomorPentingScreen> {
  final NomorPentingService _service = NomorPentingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _nomorPenting = [];

  @override
  void initState() {
    super.initState();
    _loadNomorPenting();
  }

  Future<void> _loadNomorPenting() async {
    try {
      final data = await _service.getAllNomorPenting();
      setState(() {
        _nomorPenting = data;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat nomor penting')),
      
      );
      print(e);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters and ensure proper format
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneNumber.startsWith('62')) {
      phoneNumber = '62${phoneNumber.replaceFirst(RegExp(r'^0'), '')}';
    }
    
    final whatsappUrl = "https://wa.me/$phoneNumber";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nomor Penting'),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _nomorPenting.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada nomor penting yang dibuat',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _nomorPenting.length,
                  itemBuilder: (context, index) {
                    final nomor = _nomorPenting[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _launchWhatsApp(nomor['nomor_telepon']),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFE5CC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nomor['nama_kontak'] ?? '', // Change from 'nama' to 'nama_kontak'
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      nomor['nomor_telepon'] ?? '', // Change from 'keterangan' to 'nomor_telepon'
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/dashboard_icon/wa.png',
                                width: 32,
                                height: 32,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}