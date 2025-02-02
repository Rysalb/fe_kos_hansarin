import 'package:flutter/material.dart';
import 'package:proyekkos/widgets/custom_bottom_navbar.dart';
import 'package:proyekkos/screens/bottom_navbar/account_screen.dart';
import 'package:proyekkos/screens/bottom_navbar/contact_screen.dart';
import 'package:proyekkos/screens/bottom_navbar/history_screen.dart';

class KelolaKamarPage extends StatefulWidget {
  @override
  _KelolaKamarPageState createState() => _KelolaKamarPageState();
}

class _KelolaKamarPageState extends State<KelolaKamarPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    KelolaKamarContent(),
    HistoryScreen(),
    ContactScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      // Jika menekan Beranda, kembali ke AdminDashboard
      Navigator.of(context).pop();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kamar'),
        backgroundColor: Color(0xFF99836D),
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logika untuk menambahkan kamar
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class KelolaKamarContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomInfo('Kamar Bawah', '8/8'),
          SizedBox(height: 16),
          _buildRoomInfo('Kamar Atas', '1/2'),
        ],
      ),
    );
  }

  Widget _buildRoomInfo(String title, String count) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ListTile(
        title: Text(title),
        trailing: Text(count),
      ),
    );
  }
}