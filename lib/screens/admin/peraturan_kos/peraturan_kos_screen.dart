import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/peraturan_kos_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/admin/peraturan_kos/tambah_peraturan_kos_screen.dart';

class PeraturanKosScreen extends StatefulWidget {
  @override
  _PeraturanKosScreenState createState() => _PeraturanKosScreenState();
}

class _PeraturanKosScreenState extends State<PeraturanKosScreen> {
  final PeraturanKosService _peraturanKosService = PeraturanKosService();
  final _formKey = GlobalKey<FormState>();
  final _peraturanController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _currentPeraturan;

  @override
  void initState() {
    super.initState();
    _loadPeraturan();
  }

  Future<void> _loadPeraturan() async {
    try {
      final peraturanList = await _peraturanKosService.getAllPeraturan();
      setState(() {
        _currentPeraturan = peraturanList.isNotEmpty ? peraturanList.first : null;
        if (_currentPeraturan != null) {
          _peraturanController.text = _currentPeraturan!['isi_peraturan'];
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading peraturan: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePeraturan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'isi_peraturan': _peraturanController.text,
        'tanggal_dibuat': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      bool success;
      if (_currentPeraturan != null) {
        success = await _peraturanKosService.updatePeraturan(
          _currentPeraturan!['id_peraturan'],
          data,
        );
      } else {
        success = await _peraturanKosService.createPeraturan(data);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Peraturan berhasil disimpan')),
        );
        _loadPeraturan();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan peraturan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          'Peraturan Kos Sidarame12',
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
              // Implementasi info button
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentPeraturan == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Peraturan kos masih belum dibuat',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tekan tanda + untuk membuat peraturan kos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peraturan Kos Sidarame12',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _currentPeraturan!['isi_peraturan']
                            .toString()
                            .split('\n')
                            .length,
                        itemBuilder: (context, index) {
                          final peraturanList = _currentPeraturan!['isi_peraturan']
                              .toString()
                              .split('\n');
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${index + 1}. ${peraturanList[index]}',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Peraturan ini dibuat untuk kenyamanan bersama untuk ditaati',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Di buat pada tanggal\n${DateFormat('dd MMMM yyyy').format(DateTime.parse(_currentPeraturan!['tanggal_dibuat']))}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahPeraturanKosScreen(
                currentPeraturan: _currentPeraturan,
              ),
            ),
          ).then((value) {
            if (value == true) {
              _loadPeraturan();
            }
          });
        },
        child: Image.asset(
          'assets/images/add_icon.png',
          width: 100,
          height: 100,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _peraturanController.dispose();
    super.dispose();
  }
} 