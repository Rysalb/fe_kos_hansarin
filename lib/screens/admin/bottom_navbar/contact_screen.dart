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
  List<Map<String, dynamic>> _contactList = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllUnits();
      setState(() {
        _contactList = List<Map<String, dynamic>>.from(
          data.where((unit) => unit['penyewa'] != null)
        );
        _contactList.sort((a, b) => 
          int.parse(a['nomor_kamar'].toString())
          .compareTo(int.parse(b['nomor_kamar'].toString()))
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kontak')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Hapus karakter selain angka
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Pastikan nomor dimulai dengan kode negara
    if (!phoneNumber.startsWith('62')) {
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '62${phoneNumber.substring(1)}';
      } else {
        phoneNumber = '62$phoneNumber';
      }
    }

    final url = 'https://wa.me/$phoneNumber';
    
    if (await canLaunch(url)) {
      await launch(url);
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
        title: Text('List Kontak Penghuni'),
        backgroundColor: Color(0xFFE7B789),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _contactList.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada data kontak penghuni',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _contactList.length,
                  itemBuilder: (context, index) {
                    final unit = _contactList[index];
                    final penyewa = unit['penyewa'];
                    final user = penyewa['user'];

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      color: Color(0xFFFBE1CE),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          'Kamar ${unit['nomor_kamar']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nama: ${user['name']}'),
                            Text('Asal: ${penyewa['alamat_asal']}'),
                            Text('Tanggal Masuk: ${penyewa['tanggal_masuk']}'),
                            Text('Tanggal Keluar: ${penyewa['tanggal_keluar']}'),
                            Text('No HP: ${penyewa['nomor_wa']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Image.asset(
                            'assets/images/dashboard_icon/wa.png',
                            width: 50,
                            height: 50,
                          ),
                          onPressed: () => _launchWhatsApp(penyewa['nomor_wa']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 