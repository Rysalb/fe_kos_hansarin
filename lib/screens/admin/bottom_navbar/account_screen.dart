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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildMenuButton(
            icon: 'assets/images/biodata.png',
            title: 'Biodata',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BiodataScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildMenuButton(
            icon: 'assets/images/admin.png',
            title: 'Buat Akun Tambahan Pengelola Kos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAdminScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildMenuButton(
            icon: 'assets/images/info.png',
            title: 'Tentang Aplikasi',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => CustomInfoDialog(
                  title: 'Tentang Aplikasi',
                  message: 'Aplikasi ini dibuat untuk memudahkan pengelola kos dalam memanajemen usaha kosnya.',
                ),
              );
            },
          ),
          SizedBox(height: 12),
          _buildMenuButton(
            icon: 'assets/images/logout.png',
            title: 'Keluar',
            onTap: () async {
              await _authService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFE5CC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Image.asset(
                  icon,
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A2F1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 