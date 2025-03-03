import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:proyekkos/screens/users/chat_pengelola.dart';
import 'package:proyekkos/screens/users/notifications/user_notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';
import '../../widgets/dashboard_skeleton.dart';
import '../../widgets/custom_bottom_navbarUser.dart';
import 'bottom_navbar/pesan_makanan_screen.dart';
import 'bottom_navbar/contact_screen.dart';
import 'bottom_navbar/account_screen.dart';
import 'penghuni_kamar_screen.dart';
import 'pembayaran/bayar_sewa_screen.dart';
import 'pembayaran/histori_pembayaran_screen.dart';
import 'nomor_penting_screen.dart';
import 'peraturan_kos_screen.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/data/services/notification_service.dart';
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _loadData();
    _setupUserInOneSignal();
  }

  void _initializeScreens() {
    setState(() {
      _screens = [
        _buildMainDashboard(),
        PesanMakananScreen(),
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
                            // Add new row for last payment date
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pembayaran Terakhir:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _userProfile?['pembayaran_terakhir'] != null
                                      ? DateFormat('dd/MM/yyyy').format(
                                          DateTime.parse(_userProfile!['pembayaran_terakhir']))
                                      : '-',
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BayarSewaScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/verifikasi_pembayaran.png',
                          label: 'Histori\nPembayaran',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoriPembayaranScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/nomor_penting.png',
                          label: 'Nomor\nPenting',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NomorPentingScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          imagePath: 'assets/images/dashboard_icon/peraturan_kos.png',
                          label: 'Peraturan\nKos',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PeraturanKosScreen(),
                              ),
                            );
                          },
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

      // Check for expired dates after profile is loaded
      await _checkForExpiredDates();
      
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
            automaticallyImplyLeading: false, // Add this line to remove back arrow
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/logo_kos.png'),
                  radius: 20,
                ),
                SizedBox(width: 12),
                Text(
                  '${_getGreeting()}, ${_userProfile?['name'] ?? 'User'}!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: _userProfile != null && _userProfile!['name'].toString().length > 15 
                      ? 14.0  // Smaller font for long names
                      : 16.0, // Default font size
                  ),
                  overflow: TextOverflow.ellipsis, // Add ellipsis for very long names
                  maxLines: 1, // Ensure single line
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserNotificationScreen(),
                        ),
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _notificationService.unreadCountStream,
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      if (unreadCount == 0) {
                        return SizedBox.shrink();
                      }
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

  void _setupUserInOneSignal() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    // Hapus tag lama yang mungkin masih ada
    await OneSignal.User.removeTag('role');
    await OneSignal.User.removeTag('user_id');
    
    if (userId != null) {
      // Set tag baru
      await OneSignal.User.addTagWithKey('user_id', userId);
      await OneSignal.User.addTagWithKey('role', 'user');
      
      // Print untuk verifikasi
      final tags = await OneSignal.User.getTags();
      print('====== USER TAGS ======');
      print('user_id: $userId');
      print('All tags: $tags');
      print('======================');
    }
  } catch (e) {
    print('Error setting OneSignal tags: $e');
  }
}

  Future<void> _checkForExpiredDates() async {
  try {
    if (_userProfile != null && _userProfile!['tanggal_keluar'] != null) {
      final checkoutDate = DateTime.parse(_userProfile!['tanggal_keluar']);
      final now = DateTime.now();
      final difference = checkoutDate.difference(now).inDays;
      
      print('Dashboard checkout check - Days remaining: $difference');
      
      // If checkout date is approaching (within 7 days)
      if (difference <= 7 && difference >= 0) {
        // Manually trigger the checkout reminder
        await _notificationService.checkAndSendCheckoutReminders();
      }
    }
  } catch (e) {
    print('Error checking expired dates: $e');
  }
}
}
