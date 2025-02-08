import 'package:flutter/material.dart';
import 'package:proyekkos/screens/users/chat_pengelola.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/dashboard_skeleton.dart';
import '../../widgets/custom_bottom_navbarUser.dart';
import 'bottom_navbar/history_screen.dart';
import 'bottom_navbar/contact_screen.dart';
import 'bottom_navbar/account_screen.dart';
import 'penghuni_kamar_screen.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _loadData();
  }

  void _initializeScreens() {
    setState(() {
      _screens = [
        _buildMainDashboard(),
        HistoryScreen(),
        ContactScreen(),
        AccountScreen(),
      ];
    });
  }

  Widget _buildMainDashboard() {
    return _isLoading
        ? DashboardSkeleton()
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tanggal check-in:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _userProfile?['tanggal_masuk']?.toString() ?? '-',
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tanggal Check-out:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _userProfile?['tanggal_keluar']?.toString() ?? '-',
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Nomor Kamar:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _userProfile?['nomor_kamar']?.toString() ?? '-',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/kelola_kamar.png',
                          label: 'Lihat Penghuni\nKamar Kos',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PenghuniKamarScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/wa.png',
                          label: 'Chat Pengelola\nKos',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPengelola(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/metode_pembayaran.png',
                          label: 'Bayar Sewa\nKos',
                          onTap: () {},
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/verifikasi_pembayaran.png',
                          label: 'Histori\nPembayaran',
                          onTap: () {},
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/nomor_penting.png',
                          label: 'Nomor\nPenting',
                          onTap: () {},
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/peraturan_kos.png',
                          label: 'Peraturan\nKos',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);
      final profile = await _authService.getUserProfile();
      
      if (!mounted) return;
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
        _initializeScreens();
      });
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initializeScreens();
        });
      }
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

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
            color: Color(0xFFE7B789),
          ),
          child: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/logo_kos.png'),
                  radius: 20,
                ),
                SizedBox(width: 12),
                Text(
                  '${_getGreeting()}, ${_userProfile?['name'] ?? 'User'}!',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBarUser(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFFE7B789),
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
                width: 48,
                height: 48,
              ),
              SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A2F1C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
