import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KwitansiPembayaranScreen extends StatelessWidget {
  final Map<String, dynamic> transaksi;
  
  const KwitansiPembayaranScreen({
    Key? key,
    required this.transaksi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Rincian Pembayaran'),
        backgroundColor: Color(0xFFE7B789),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Pembayaran Berhasil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pembayaran telah diterima',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Total Payment',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        formatter.format(double.parse(transaksi['jumlah'].toString())),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildInfoRow(
                      'Nomor\nPembayaran',
                      transaksi['id'].toString().padLeft(11, '0'),
                    ),
                    _buildInfoRow(
                      'Tanggal\nPembayaran',
                      DateFormat('dd MMMM yyyy').format(
                        DateTime.parse(transaksi['tanggal']),
                      ),
                    ),
                    _buildInfoRow(
                      'Pembayaran\nMelalui',
                      transaksi['metode_pembayaran'] ?? 'BCA',
                    ),
                    _buildInfoRow(
                      'Status',
                      'Terverifikasi',
                      isVerified: true,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesan Pengelola :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    transaksi['keterangan'] ?? 'Uang sudah saya terima\nTerimakasih !',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (isVerified) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 