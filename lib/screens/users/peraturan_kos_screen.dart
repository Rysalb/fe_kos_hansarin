import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/peraturan_kos_service.dart';
import 'package:intl/intl.dart';

class PeraturanKosScreen extends StatefulWidget {
  @override
  _PeraturanKosScreenState createState() => _PeraturanKosScreenState();
}

class _PeraturanKosScreenState extends State<PeraturanKosScreen> {
  final PeraturanKosService _service = PeraturanKosService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _peraturanKos = [];

  @override
  void initState() {
    super.initState();
    _loadPeraturanKos();
  }

  Future<void> _loadPeraturanKos() async {
    try {
      final data = await _service.getAllPeraturan();
      setState(() {
        _peraturanKos = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading peraturan: $e'); // Add debug print
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat peraturan kos: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peraturan Kos'),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _peraturanKos.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada peraturan kos yang dibuat',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peraturan Kos Sidorame12',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _peraturanKos.length,
                        itemBuilder: (context, index) {
                          final peraturan = _peraturanKos[index];
                          final peraturanText = peraturan['isi_peraturan']?.toString() ?? '';
                          final rules = peraturanText.split('\n');
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: rules.map((rule) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${rules.indexOf(rule) + 1}. '),
                                  Expanded(child: Text(rule)),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Peraturan ini dibuat untuk kenyamanan bersama untuk ditaati',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Di buat pada tanggal',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        _peraturanKos.isNotEmpty
                            ? DateFormat('dd MMMM yyyy').format(
                                DateTime.parse(_peraturanKos[0]['created_at']))
                            : '-',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
    );
  }
}