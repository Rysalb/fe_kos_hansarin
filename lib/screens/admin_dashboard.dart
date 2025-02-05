import 'package:flutter/material.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/account_screen.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/contact_screen.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/history_screen.dart';
import 'package:proyekkos/screens/admin/kelola_kamar.dart';
import 'package:proyekkos/screens/admin/kelola_penyewa.dart';
import 'package:proyekkos/widgets/custom_bottom_navbar.dart';


class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AdminDashboardContent(),
    HistoryScreen(),
    ContactScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF99836D),
                Color(0xFFFFF8E7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/logo_kos.png'),
                  radius: 20,
                ),
                SizedBox(width: 12),
                Text('Selamat Pagi, Bu Umi !'),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  print('Notifikasi ditekan');
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}




class AdminDashboardContent extends StatelessWidget {
 @override
  Widget build(BuildContext context) {
    return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Informasi Kamar
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromARGB(31, 58, 57, 57), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Kamar Terisi : 9'),
                            Text('Kamar Kosong : 1'),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Kamar dengan durasi sewa akan habis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildExpiryRow('Kamar 1', '29 September 2024'),
                        _buildExpiryRow('Kamar 2', '29 September 2024'),
                        _buildExpiryRow('Kamar 3', '29 September 2024'),
                        _buildExpiryRow('Kamar 4', '29 September 2024'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Grid Menu
              Expanded(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/kelola_kamar.png',
                      label: 'Kelola\nKamar',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => KelolaKamarPage()));
                      },
                    ),
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/identitas_penyewa.png',
                      label: 'Kelola Identitas\nPenyewa',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => KelolaPenyewaPage()),
                        );
                      },
                    ),
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/pembukuan.png',
                      label: 'Pembukuan\nKeuangan',
                      onTap: () {},
                    ),
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/verifikasi_pembayaran.png',
                      label: 'Verifikasi Laporan\nPembayaran',
                      onTap: () {},
                    ),
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/nomor_penting.png',
                      label: 'Kelola Nomor\nPenting',
                      onTap: () {},
                    ),
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/metode_pembayaran.png',
                      label: 'Metode\nPembayaran',
                      onTap: () {},
                    ),
                    _buildMenuCard(
                      imagePath: 'assets/images/dashboard_icon/peraturan_kos.png',
                      label: 'Buat Peraturan\nKos',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
    );

  }

  Widget _buildExpiryRow(String kamar, String tanggal) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 10),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(kamar)),
          Expanded(child: Text('Berakhir pada tanggal : $tanggal', textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                width: 32,
                height: 32,
              ),
              SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4A2F1C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 