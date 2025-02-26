import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/auth_service.dart';
import 'package:proyekkos/screens/admin/add_admin_screen.dart';
import 'package:proyekkos/screens/admin/biodata/biodata_screen.dart';
import 'package:proyekkos/widgets/custom_info_dialog.dart';

class AccountScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E7), Color(0xFFFFE5CC)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Profile Section
            Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE7B789),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2F1C),
                    ),
                  ),
                ],
              ),
            ),
            ..._buildMenuButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuButtons(BuildContext context) {
    return [
      _buildMenuButton(
        icon: 'assets/images/biodata.png',
        title: 'Biodata',
        subtitle: 'Lihat dan edit informasi profil',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BiodataScreen()),
        ),
      ),
      _buildMenuButton(
        icon: 'assets/images/admin.png',
        title: 'Buat Akun Tambahan',
        subtitle: 'Tambah pengelola kos baru',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddAdminScreen()),
        ),
      ),
      _buildMenuButton(
        icon: 'assets/images/info.png',
        title: 'Tentang Aplikasi',
        subtitle: 'Informasi dan bantuan',
        onTap: () => showDialog(
          context: context,
          builder: (context) => CustomInfoDialog(
            title: 'Tentang Aplikasi',
            message: 'Aplikasi ini dibuat untuk memudahkan pengelola kos dalam memanajemen usaha kosnya.',
          ),
        ),
      ),
      _buildMenuButton(
        icon: 'assets/images/logout.png',
        title: 'Keluar',
        subtitle: 'Keluar dari akun',
        onTap: () async {
          await _authService.logout();
          Navigator.of(context).pushReplacementNamed('/login');
        },
        isLogout: true,
      ),
    ];
  }

  Widget _buildMenuButton({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLogout ? Color(0xFFFFEEEE) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLogout ? Color(0xFFFFE5E5) : Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    icon,
                    width: 24,
                    height: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLogout ? Colors.red : Color(0xFF4A2F1C),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isLogout ? Colors.red : Color(0xFF4A2F1C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}