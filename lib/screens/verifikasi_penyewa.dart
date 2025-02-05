import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/auth_service.dart';
import 'package:proyekkos/widgets/custom_info_dialog.dart';

class VerifikasiPenyewaScreen extends StatefulWidget {
  @override
  _VerifikasiPenyewaScreenState createState() => _VerifikasiPenyewaScreenState();
}

class _VerifikasiPenyewaScreenState extends State<VerifikasiPenyewaScreen> {
  final AuthService _authService = AuthService();
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

  Future<void> _handleVerifikasi(Map<String, dynamic> user) async {
    try {
      await _authService.verifikasiUser(
        user['id_user'],
        'disetujui',
        DateTime.now(),
        1,
      );
      _fetchPendingUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil memverifikasi penyewa')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memverifikasi: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleTolak(Map<String, dynamic> user) async {
    try {
      await _authService.verifikasiUser(
        user['id_user'],
        'ditolak',
        null,
        null,
      );
      _fetchPendingUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil menolak penyewa')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak: ${e.toString()}')),
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
          style: TextStyle(color: Colors.black),
        ),
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
                                  '${user['nomor_kamar'] ?? 'Tidak tersedia'}',
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
                                      'No HP: ${user['nomor_wa'] ?? 'Tidak tersedia'}',
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
                                  onPressed: () => _handleTolak(user),
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