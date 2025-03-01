import 'package:flutter/material.dart';
import 'package:proyekkos/data/services/pembayaran_service.dart';
import 'package:intl/intl.dart';
import 'package:proyekkos/screens/admin/pembukuan/kwitansi_pembayaran_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final PembayaranService _service = PembayaranService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _orderHistory = [];
  String? _selectedYear;
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _initializeYears();
    _loadOrderHistory();
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    _years = List.generate(4, (index) => (currentYear - index).toString());
    _selectedYear = currentYear.toString();
  }

  Future<void> _loadOrderHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getHistoriPembayaran(year: _selectedYear!);
      // Filter only order menu transactions
      final orderData = data.where((item) => item['keterangan'] == 'Order Menu').toList();
      setState(() {
        _orderHistory = orderData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat histori pesanan')),
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
      default:
        return Color(0xFFFFE5CC);
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) {
    if (order['status'].toString().toLowerCase() == 'verified') {
      _showKwitansiDialog(order);
    } else if (order['status'].toString().toLowerCase() == 'pending') {
      _showPendingDialog(order);
    } else if (order['status'].toString().toLowerCase() == 'rejected') {
      _showRejectedDialog(order);
    }
  }

  void _showKwitansiDialog(Map<String, dynamic> order) {
    final jumlah = order['jumlah_pembayaran'] != null 
        ? num.tryParse(order['jumlah_pembayaran'].toString()) ?? 0 
        : 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KwitansiPembayaranScreen(
          transaksi: {
            'jumlah_pembayaran': jumlah,
            'id_pembayaran': order['id']?.toString() ?? '',
            'tanggal': order['tanggal_pembayaran']?.toString() ?? DateTime.now().toString(),
            'metode_pembayaran': order['metode_pembayaran']?['nama_metode']?.toString() ?? 'Tidak diketahui',
            'keterangan': 'Order Menu',
          },
        ),
      ),
    );
  }

  void _showPendingDialog(Map<String, dynamic> order) {
    // Convert jumlah_pembayaran to num
    final jumlah = order['jumlah_pembayaran'] != null 
        ? num.tryParse(order['jumlah_pembayaran'].toString()) ?? 0 
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status Pesanan: Pending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(order['tanggal_pembayaran'] ?? DateTime.now().toString()))}'),
            SizedBox(height: 8),
            Text('Total: ${NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(jumlah)}'),
            SizedBox(height: 8),
            Text('Metode: ${order['metode_pembayaran']?['nama_metode'] ?? 'Tidak diketahui'}'),
            SizedBox(height: 16),
            Text('Menunggu verifikasi dari admin...'),
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

  void _showRejectedDialog(Map<String, dynamic> order) {
    // Convert jumlah_pembayaran to num
    final jumlah = order['jumlah_pembayaran'] != null 
        ? num.tryParse(order['jumlah_pembayaran'].toString()) ?? 0 
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Status Pesanan: Ditolak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(order['tanggal_pembayaran'] ?? DateTime.now().toString()))}'),
            SizedBox(height: 8),
            Text('Total: ${NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(jumlah)}'),
            SizedBox(height: 8),
            Text('Metode: ${order['metode_pembayaran']?['nama_metode'] ?? 'Tidak diketahui'}'),
            SizedBox(height: 16),
            Text('Alasan Penolakan:'),
            Text(order['keterangan'] ?? 'Tidak ada keterangan',
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

  Widget _buildListItem(Map<String, dynamic> order) {
    final tanggal = DateFormat('dd-MM-yyyy').format(
      DateTime.parse(order['tanggal_pembayaran']?.toString() ?? DateTime.now().toString())
    );
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(order['status']?.toString() ?? ''),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _showOrderDetail(order),
        leading: Image.asset(
          'assets/images/pesanmakan.png',
          width: 40,
          height: 40,
        ),
        title: Text('Order Menu'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tanggal),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(num.tryParse(order['jumlah_pembayaran'].toString()) ?? 0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          order['status']?.toString() ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: (order['status']?.toString()?.toLowerCase() ?? '') == 'ditolak'
                ? Colors.red
                : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histori Pesanan'),
        backgroundColor: Color(0xFFE7B789),
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
                      _loadOrderHistory();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _orderHistory.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada pesanan yang dilakukan',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _orderHistory.length,
                        itemBuilder: (context, index) {
                          final order = _orderHistory[index];
                          return _buildListItem(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}