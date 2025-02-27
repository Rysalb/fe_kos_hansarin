import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/admin/pembukuan/kwitansi_pembayaran_screen.dart';
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
      case 'verified':
        return Color.fromARGB(255, 166, 207, 163);
      case 'rejected':
        return Color(0xFFFFCCCC);
      case 'pending':
        return Colors.grey[300]!;
      case 'proses':
        return Colors.grey[300]!;
      default:
        return Color(0xFFFFE5CC);
    }
  }

  void _showPaymentDetail(Map<String, dynamic> pembayaran) {
    final status = pembayaran['status'].toString().toLowerCase();
    
    switch (status) {
      case 'verified':
        _showKwitansiDialog(pembayaran);
        break;
      case 'pending':
        _showPendingDialog(pembayaran);
        break;
      case 'rejected':
        _showRejectedDialog(pembayaran);
        break;
    }
  }

  void _showKwitansiDialog(Map<String, dynamic> pembayaran) {
    // Convert jumlah_pembayaran to number first
    final jumlah = pembayaran['jumlah_pembayaran'] != null 
        ? num.tryParse(pembayaran['jumlah_pembayaran'].toString()) ?? 0 
        : 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KwitansiPembayaranScreen(
          transaksi: {
            'jumlah_pembayaran': jumlah,
            'id_pembayaran': pembayaran['id']?.toString() ?? '',
            'tanggal': pembayaran['tanggal_pembayaran']?.toString() ?? DateTime.now().toString(),
            'metode_pembayaran': pembayaran['metode_pembayaran']?['nama_metode']?.toString() ?? 'Tidak diketahui',
            'keterangan': pembayaran['keterangan']?.toString() ?? '',
          },
        ),
      ),
    );
  }

  void _showPendingDialog(Map<String, dynamic> pembayaran) {
    // Convert jumlah_pembayaran to num
    final jumlah = pembayaran['jumlah_pembayaran'] != null 
        ? num.tryParse(pembayaran['jumlah_pembayaran'].toString()) ?? 0 
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status Pembayaran: Pending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(pembayaran['tanggal'] ?? DateTime.now().toString()))}'),
            SizedBox(height: 8),
            Text('Jumlah: ${NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(jumlah)}'),
            SizedBox(height: 8),
            Text('Metode: ${pembayaran['metode_pembayaran']?['nama_metode'] ?? 'Tidak diketahui'}'),
            SizedBox(height: 16),
            Text('Menunggu verifikasi dari admin'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog(Map<String, dynamic> pembayaran) {
    // Convert jumlah_pembayaran to num
    final jumlah = pembayaran['jumlah_pembayaran'] != null 
        ? num.tryParse(pembayaran['jumlah_pembayaran'].toString()) ?? 0 
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status Pembayaran: Ditolak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(pembayaran['tanggal'] ?? DateTime.now().toString()))}'),
            SizedBox(height: 8),
            Text('Jumlah: ${NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(jumlah)}'),
            SizedBox(height: 8),
            Text('Metode: ${pembayaran['metode_pembayaran']?['nama_metode'] ?? 'Tidak diketahui'}'),
            SizedBox(height: 16),
            Text('Alasan Penolakan:'),
            Text(pembayaran['keterangan'] ?? 'Tidak ada keterangan',
                style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> pembayaran) {
    final tanggal = DateFormat('dd-MM-yyyy').format(
      DateTime.parse(pembayaran['tanggal_pembayaran']?.toString() ?? DateTime.now().toString())
    );
    
    // Check if it's an order menu or rent payment
    final bool isOrderMenu = pembayaran['keterangan'] == 'Order Menu';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(pembayaran['status']?.toString() ?? ''),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _showPaymentDetail(pembayaran),
        leading: Image.asset(
          isOrderMenu ? 'assets/images/pesanmakan.png' : 'assets/images/avatar.png',
          width: 40,
          height: 40,
        ),
        title: Text(isOrderMenu ? 'Order Menu' : 'Bayar Sewa'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tanggal),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(num.tryParse(pembayaran['jumlah_pembayaran'].toString()) ?? 0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pembayaran['status']?.toString() ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (pembayaran['status']?.toString()?.toLowerCase() ?? '') == 'ditolak'
                    ? Colors.red
                    : Colors.black,
              ),
            ),
            if (isOrderMenu)
              Text(
                'Pesanan Makanan',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
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
                          return _buildListItem(pembayaran);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}