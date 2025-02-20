import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'package:intl/intl.dart';

class HistoriPembayaranScreen extends StatefulWidget {
  @override
  _HistoriPembayaranScreenState createState() => _HistoriPembayaranScreenState();
}

class _HistoriPembayaranScreenState extends State<HistoriPembayaranScreen> {
  final PembayaranService _service = PembayaranService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _historiPembayaran = [];
  String? _selectedYear;
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _initializeYears();
    _loadHistoriPembayaran();
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    _years = List.generate(4, (index) => (currentYear - index).toString());
    _selectedYear = currentYear.toString();
  }

  Future<void> _loadHistoriPembayaran() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getHistoriPembayaran(year: _selectedYear!);
      setState(() {
        _historiPembayaran = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat histori pembayaran')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'terverifikasi':
        return Color(0xFFFFE5CC);
      case 'ditolak':
        return Color(0xFFFFCCCC);
      case 'proses':
        return Colors.grey[300]!;
      default:
        return Color(0xFFFFE5CC);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histori Pembayaran'),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Tahun:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFE5CC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: _years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedYear = value);
                      _loadHistoriPembayaran();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _historiPembayaran.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada pembayaran yang dilakukan',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _historiPembayaran.length,
                        itemBuilder: (context, index) {
                          final pembayaran = _historiPembayaran[index];
                          final tanggal = DateFormat('dd-MM-yyyy')
                              .format(DateTime.parse(pembayaran['tanggal']));
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(pembayaran['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text('Bayar Sewa'),
                              subtitle: Text(tanggal),
                              trailing: Text(
                                pembayaran['status'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: pembayaran['status'].toLowerCase() == 'ditolak'
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 