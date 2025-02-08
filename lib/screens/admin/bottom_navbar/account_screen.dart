import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/auth_service.dart';

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
              // Navigasi ke halaman biodata
            },
          ),
          SizedBox(height: 12),
          _buildMenuButton(
            icon: 'assets/images/admin.png',
            title: 'Buat Akun Tambahan Pengelola Kos',
            onTap: () {
              // Navigasi ke halaman buat akun tambahan
            },
          ),
          SizedBox(height: 12),
          _buildMenuButton(
            icon: 'assets/images/info.png',
            title: 'Tentang Aplikasi',
            onTap: () {
              // Navigasi ke halaman tentang aplikasi
            },
          ),
          SizedBox(height: 12),
          _buildMenuButton(
            icon: 'assets/images/logout.png',
            title: 'Keluar',
            onTap: () async {
              // Implementasi logout
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