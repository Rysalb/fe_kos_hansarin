import 'package:flutter/material.dart';
import 'package:proyekkos/widgets/custom_bottom_navbarAdmin.dart';
import 'package:proyekkos/data/services/kamar_service.dart';
import 'package:proyekkos/screens/admin/kelola_kamar/tambah_kamar.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/account_screen.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/contact_screen.dart';
import 'package:proyekkos/screens/admin/bottom_navbar/history_screen.dart';
import 'package:proyekkos/screens/admin/admin_dashboard.dart';
import 'package:proyekkos/screens/admin/kelola_kamar/ubah_kamar.dart';
import 'package:proyekkos/widgets/custom_info_dialog.dart';

class KelolaKamarPage extends StatefulWidget {
  @override
  _KelolaKamarPageState createState() => _KelolaKamarPageState();
}

class _KelolaKamarPageState extends State<KelolaKamarPage> {
  final KamarService _kamarService = KamarService();
  // ignore: unused_field
  List<Map<String, dynamic>> _kamarList = []; // Digunakan untuk menyimpan data kamar
  bool _isLoading = true;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    KelolaKamarContent(),
    HistoryScreen(),
    ContactScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchKamarData();
  }

  Future<void> _fetchKamarData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _kamarService.getAllKamar();
      if (response != null) {
        setState(() {
          _kamarList = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching kamar data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == 0 && _selectedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboardPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
     appBar: AppBar(
        title: Text(
          'Kelola Kamar',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
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
                    message: 'Tekan icon + untuk menambahkan kamar baru, tekan salah satu list kamar untuk mengubah data kamar, dan geser salah satu list kamar untuk menghapus kamar',
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
      floatingActionButton: _selectedIndex == 0 ? GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahKamarPage()),
          ).then((_) => _fetchKamarData());
        },
        child: Image.asset(
          'assets/images/add_icon.png',
          width: 100,
          height: 100,
        ),
      ) : null,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Buat widget baru untuk konten Kelola Kamar
class KelolaKamarContent extends StatefulWidget {
  @override
  _KelolaKamarContentState createState() => _KelolaKamarContentState();
}

class _KelolaKamarContentState extends State<KelolaKamarContent> {
  final KamarService _kamarService = KamarService();
  List<Map<String, dynamic>> _kamarList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKamarData();
  }

  Future<void> _fetchKamarData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _kamarService.getAllKamar();
      if (response != null) {
        setState(() {
          _kamarList = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching kamar data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKamar(int idKamar) async {
    try {
      final success = await _kamarService.deleteKamar(idKamar);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamar berhasil dihapus')),
        );
        _fetchKamarData(); // Refresh data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus kamar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: _kamarList.length,
            itemBuilder: (context, index) {
              final kamar = _kamarList[index];
              final totalUnit = kamar['unit_kamar']?.length ?? 0;
              final terisiUnit = kamar['unit_kamar']
                      ?.where((unit) => unit['status'] == 'dihuni')
                      .length ??
                  0;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Dismissible(
                  key: Key(kamar['id_kamar'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.0),
                    color: Colors.red,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        Text('Hapus', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Konfirmasi'),
                          content: Text('Yakin ingin menghapus kamar ini?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Hapus'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _deleteKamar(kamar['id_kamar']);
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UbahKamarPage(kamar: kamar),
                        ),
                      ).then((_) => _fetchKamarData());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFE5CC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          kamar['tipe_kamar'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          '$terisiUnit/$totalUnit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}