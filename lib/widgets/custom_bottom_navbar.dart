import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = const Color(0xFFE7B789),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Color(0xFF4A2F1C),
        unselectedItemColor: Colors.grey,
        items: [
          _buildNavBarItem(
            icon: 'assets/images/icon_botnav/home.png',
            activeIcon: 'assets/images/icon_botnav/home_aktif.png',
            label: 'Beranda',
          ),
          _buildNavBarItem(
            icon: 'assets/images/icon_botnav/katalog.png',
            activeIcon: 'assets/images/icon_botnav/katalog_aktif.png',
            label: 'Katalog Menu',
          ),
          _buildNavBarItem(
            icon: 'assets/images/icon_botnav/kontak.png',
            activeIcon: 'assets/images/icon_botnav/kontak_aktif.png',
            label: 'Kontak',
          ),
          _buildNavBarItem(
            icon: 'assets/images/icon_botnav/akun.png',
            activeIcon: 'assets/images/icon_botnav/akun_aktif.png',
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavBarItem({
    required String icon,
    required String activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        icon,
        width: 24,
        height: 24,
        color: Colors.grey,
      ),
      activeIcon: Image.asset(
        activeIcon,
        width: 24,
        height: 24,
        color: Color(0xFF4A2F1C),
      ),
      label: label,
    );
  }
} 