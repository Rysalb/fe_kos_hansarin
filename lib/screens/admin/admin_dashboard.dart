import 'package:flutter/material.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/account_screen.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/contact_screen.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/history_screen.dart';
import 'package:proyekkos/screens/admin/kelola_kamar/kelola_kamar.dart';
import 'package:proyekkos/screens/admin/kelola_penyewa/kelola_penyewa.dart';
import 'package:proyekkos/widgets/custom_bottom_navbarAdmin.dart';
import 'package:proyekkos/data/services/auth_service.dart';
import 'package:proyekkos/data/services/kamar_service.dart';
import 'package:proyekkos/widgets/dashboardAdmin_skeleton.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final KamarService _kamarService = KamarService();
  Map<String, dynamic>? _adminProfile;
  Map<String, dynamic>? _kamarStats;
  List<Map<String, dynamic>> _expiringRooms = [];
  bool _isLoading = true;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardContent(
        kamarStats: _kamarStats,
        expiringRooms: _expiringRooms,
        onRefresh: _loadData,
      ),
      HistoryScreen(),
      ContactScreen(),
      AccountScreen(),
    ];
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() => _isLoading = true);

      // Tangani setiap request secara terpisah
      Map<String, dynamic>? profile;
      Map<String, dynamic> stats = {'terisi': 0, 'kosong': 0};
      List<Map<String, dynamic>> expiring = [];

      try {
        profile = await _authService.getUserProfile();
      } catch (e) {
        print('Error loading profile: $e');
      }

      try {
        stats = await _kamarService.getKamarStats();
        print('Loaded stats: $stats'); // Debug log
      } catch (e) {
        print('Error loading stats: $e');
      }

      try {
        expiring = await _kamarService.getExpiringRooms();
        print('Loaded expiring: $expiring'); // Debug log
      } catch (e) {
        print('Error loading expiring rooms: $e');
      }

      if (!mounted) return;

      setState(() {
        _adminProfile = profile;
        _kamarStats = stats;
        _expiringRooms = expiring;
        _isLoading = false;
        _screens = [
          AdminDashboardContent(
            key: ValueKey('dashboard_${DateTime.now().millisecondsSinceEpoch}'),
            kamarStats: stats,
            expiringRooms: expiring,
            onRefresh: _loadData,
          ),
          HistoryScreen(),
          ContactScreen(),
          AccountScreen(),
        ];
      });
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _screens = [
            AdminDashboardContent(
              key: ValueKey('error_${DateTime.now().millisecondsSinceEpoch}'),
              kamarStats: {'terisi': 0, 'kosong': 0},
              expiringRooms: [],
              onRefresh: _loadData,
            ),
            HistoryScreen(),
            ContactScreen(),
            AccountScreen(),
          ];
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
                  '${_getGreeting()}, ${_adminProfile?['name'] ?? 'Admin'}!',
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
                onPressed: () {
                  print('Notifikasi ditekan');
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? DashboardSkeleton()
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xFFE7B789),
      ),
    );
  }
}

class AdminDashboardContent extends StatefulWidget {
  final Map<String, dynamic>? kamarStats;
  final List<Map<String, dynamic>> expiringRooms;
  final VoidCallback onRefresh;

  const AdminDashboardContent({
    Key? key,
    this.kamarStats,
    this.expiringRooms = const [],
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<AdminDashboardContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building AdminDashboardContent with stats: ${widget.kamarStats}'); // Debug log
    print('Building AdminDashboardContent with expiring: ${widget.expiringRooms}'); // Debug log
    
    return RefreshIndicator(
      onRefresh: () async {
         widget.onRefresh();
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(31, 58, 57, 57),
                      width: 2,
                    ),
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
                            Text(
                              'Kamar Terisi : ${widget.kamarStats?['terisi'] ?? 0}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2F1C),
                              ),
                            ),
                            Text(
                              'Kamar Kosong : ${widget.kamarStats?['kosong'] ?? 0}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A2F1C),
                              ),
                            ),
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
                        if (widget.expiringRooms.isEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tidak ada kamar yang akan habis masa sewanya dalam waktu dekat',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          )
                        else
                          ...widget.expiringRooms.map((room) => _buildExpiryRow(
                                room['nomor_kamar'],
                                room['tanggal_keluar'],
                              )).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200, // Memastikan scroll bekerja
                ),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => KelolaKamarPage()),
                        );
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
        ),
      ),
    );
  }

  Widget _buildExpiryRow(String kamar, String tanggal) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              kamar,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              'Berakhir pada tanggal : ${DateFormat('dd MMMM yyyy').format(DateTime.parse(tanggal))}',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13),
            ),
          ),
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