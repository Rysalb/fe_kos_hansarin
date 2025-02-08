import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/kamar_service.dart';
import 'package:proyekkos/data/services/penyewa_service.dart';
import 'package:intl/intl.dart';

class PindahKamarPage extends StatefulWidget {
  final int idPenyewa;
  final String currentKamar;

  PindahKamarPage({
    required this.idPenyewa,
    required this.currentKamar,
  });

  @override
  _PindahKamarPageState createState() => _PindahKamarPageState();
}

class _PindahKamarPageState extends State<PindahKamarPage> {
  final KamarService _kamarService = KamarService();
  final PenyewaService _penyewaService = PenyewaService();
  
  String? selectedTipeKamar;
  String? selectedNomorKamar;
  List<dynamic> kamarList = [];
  List<dynamic> unitList = [];
  bool isLoading = false;
  Map<String, dynamic>? penyewaDetail;

  @override
  void initState() {
    super.initState();
    _loadKamarData();
    _loadPenyewaDetail();
  }

  Future<void> _loadKamarData() async {
    setState(() => isLoading = true);
    try {
      final kamarData = await _kamarService.getAllKamar();
      if (kamarData != null) {
        setState(() {
          kamarList = kamarData;
        });
      }
    } catch (e) {
      print('Error loading kamar: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadUnitTersedia(String idKamar) async {
    setState(() => isLoading = true);
    try {
      final units = await _penyewaService.getUnitTersedia(idKamar);
      setState(() {
        unitList = units;
        selectedNomorKamar = null;
      });
    } catch (e) {
      print('Error loading units: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _pindahKamar() async {
    if (selectedNomorKamar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih nomor kamar baru'))
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // Implementasi API pindah kamar
      // Perlu menambahkan endpoint baru di backend
      await _penyewaService.pindahKamar(
        widget.idPenyewa,
        int.parse(selectedNomorKamar!),
      );

      Navigator.pop(context, true); // Kembali dengan status sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil pindah kamar'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal pindah kamar: $e'))
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadPenyewaDetail() async {
    setState(() => isLoading = true);
    try {
      final detail = await _penyewaService.getPenyewaById(widget.idPenyewa);
      setState(() {
        penyewaDetail = detail;
      });
    } catch (e) {
      print('Error loading penyewa detail: $e');
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text('Pindah Kamar', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: penyewaDetail?['user']?['name'] ?? 'Loading...'
              ),
              decoration: InputDecoration(
                labelText: 'Nama Penyewa',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: penyewaDetail?['alamat_asal'] ?? 'Loading...'
              ),
              decoration: InputDecoration(
                labelText: 'Alamat Asal',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedTipeKamar,
              decoration: InputDecoration(
                labelText: 'Tipe Kamar',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: kamarList.map((kamar) {
                return DropdownMenuItem(
                  value: kamar['id_kamar'].toString(),
                  child: Text(kamar['tipe_kamar']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTipeKamar = value;
                  if (value != null) {
                    _loadUnitTersedia(value);
                  }
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedNomorKamar,
              decoration: InputDecoration(
                labelText: 'Nomor Kamar',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: unitList.map((unit) {
                return DropdownMenuItem(
                  value: unit['id_unit'].toString(),
                  child: Text(unit['nomor_kamar']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedNomorKamar = value;
                });
              },
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE7E7E7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan', 
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kamar Lama'),
                          Text(widget.currentKamar,
                            style: TextStyle(fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      Text('Pindah ke'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Kamar Baru'),
                          Text(
                            selectedNomorKamar != null 
                              ? unitList.firstWhere((unit) => 
                                  unit['id_unit'].toString() == selectedNomorKamar
                                )['nomor_kamar']
                              : '-',
                            style: TextStyle(fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _pindahKamar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE7B789),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Pindah',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      )
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 