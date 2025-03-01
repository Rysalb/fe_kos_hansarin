import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ListAdminScreen extends StatefulWidget {
  @override
  _ListAdminScreenState createState() => _ListAdminScreenState();
}

class _ListAdminScreenState extends State<ListAdminScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _adminList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminList();
  }

  Future<void> _loadAdminList() async {
    try {
      final admins = await _authService.getAdminList();
      setState(() {
        _adminList = admins;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar admin')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    try {
      // Format nomor WhatsApp
      String formattedNumber = phoneNumber;
      if (phoneNumber.startsWith('0')) {
        formattedNumber = '62${phoneNumber.substring(1)}';
      }
      
      final Uri whatsappUri = Uri.parse('https://wa.me/$formattedNumber');
      
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun Pengelola', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
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
                            'Menambah Akun Pengelola:',
                            [
                              '1. Tekan tombol + di halaman utama',
                              '2. Isi data pengelola yang diperlukan',
                              '3. Pastikan nomor WhatsApp aktif',
                              '4. Tekan tombol Simpan',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Menghubungi Pengelola:',
                            [
                              '1. Tekan icon WhatsApp pada list',
                              '2. Aplikasi akan membuka WhatsApp',
                              '3. Mulai chat dengan pengelola',
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoSection(
                            'Menghapus Akun Pengelola:',
                            [
                              '1. Geser item ke kiri',
                              '2. Konfirmasi penghapusan',
                              '3. Akun akan dihapus dari sistem',
                              'Catatan: Akun admin@admin.com tidak dapat dihapus',
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
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _adminList.isEmpty
              ? Center(
                  child: Text('Tidak ada akun pengelola tambahan'),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _adminList.length,
                  itemBuilder: (context, index) {
                    final admin = _adminList[index];
                    
                    // Skip deletion functionality for main admin
                    if (admin['email'] == 'admin@admin.com') {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: Color(0xFFFFE5CC),
                        child: _buildListTile(admin),
                      );
                    }

                    return Dismissible(
                      key: Key(admin['id_user'].toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) => _showDeleteConfirmation(context, admin),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            Text('Hapus', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      onDismissed: (direction) => _deleteAdmin(admin['id_user']),
                      child: Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: Color(0xFFFFE5CC),
                        child: _buildListTile(admin),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> admin) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(0xFF4A2F1C),
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        admin['name'] ?? 'Pengelola',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(admin['email'] ?? ''),
          Text(admin['nomor_wa'] ?? ''),
        ],
      ),
      trailing: IconButton(
        icon: Image.asset(
          'assets/images/dashboard_icon/wa.png',
          width: 24,
          height: 24,
        ),
        onPressed: () {
          if (admin['nomor_wa'] != null) {
            _launchWhatsApp(admin['nomor_wa']);
          }
        },
      ),
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

  Future<bool?> _showDeleteConfirmation(BuildContext context, Map<String, dynamic> admin) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus akun pengelola "${admin['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdmin(int userId) async {
    try {
      await _authService.deleteUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Akun pengelola berhasil dihapus')),
      );
      _loadAdminList(); // Reload the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus akun pengelola')),
      );
    }
  }
}