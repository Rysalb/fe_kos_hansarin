import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class KwitansiPembayaranScreen extends StatelessWidget {
  final Map<String, dynamic> transaksi;
  
  KwitansiPembayaranScreen({
    Key? key,
    required this.transaksi,
  }) : super(key: key);

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      final pdf = pw.Document();
      
      // Load image
      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo_kos.png')).buffer.asUint8List(),
      );
      
      // Convert amount and format it
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      
      final jumlah = transaksi['jumlah_pembayaran'] != null 
          ? (transaksi['jumlah_pembayaran'] is num 
              ? (transaksi['jumlah_pembayaran'] as num).toDouble()
              : double.tryParse(transaksi['jumlah_pembayaran'].toString()) ?? 0.0)
          : 0.0;

      // Get id_pembayaran and ensure it's padded
      final nomorPembayaran = (transaksi['id_pembayaran'] ?? '')
          .toString()
          .padLeft(8, '0');

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Container(
            color: PdfColors.grey100,
            child: pw.Column(
              children: [
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.black,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Add logo at the top
                      pw.Center(
                        child: pw.Image(imageLogo, width: 80, height: 80),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Center(
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'Pembayaran Berhasil',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 20,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Pembayaran telah diterima',
                              style: pw.TextStyle(
                                color: PdfColors.grey400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 24),
                      pw.Center(
                        child: pw.Text(
                          'Total Payment',
                          style: pw.TextStyle(
                            color: PdfColors.grey400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.Center(
                        child: pw.Text(
                          formatter.format(jumlah),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 24),
                      // Info rows
                      _buildPdfInfoRow(
                        'Nomor Pembayaran',
                        nomorPembayaran,
                      ),
                      _buildPdfInfoRow(
                        'Tanggal Pembayaran',
                        DateFormat('dd MMMM yyyy').format(
                          DateTime.parse(transaksi['tanggal'] ?? DateTime.now().toString()),
                        ),
                      ),
                      _buildPdfInfoRow(
                        'Pembayaran Melalui',
                        transaksi['metode_pembayaran'] ?? 'Tidak diketahui',
                      ),
                      _buildPdfInfoRow(
                        'Status',
                        'Terverifikasi',
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Pesan Pengelola :',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        transaksi['keterangan'] ?? 'Uang sudah saya terima\nTerimakasih !',
                        style: pw.TextStyle(
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'kwitansi_${DateTime.now().millisecondsSinceEpoch}.pdf'
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kwitansi berhasil dibagikan'))
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membagikan kwitansi'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ', // Ubah dari IDR ke Rp
      decimalDigits: 0,
    );

    // Convert jumlah_pembayaran to double safely
    final jumlah = transaksi['jumlah_pembayaran'] != null 
        ? (transaksi['jumlah_pembayaran'] is num 
            ? (transaksi['jumlah_pembayaran'] as num).toDouble()
            : double.tryParse(transaksi['jumlah_pembayaran'].toString()) ?? 0.0)
        : 0.0;

    // Get id_pembayaran and ensure it's padded
    final nomorPembayaran = (transaksi['id_pembayaran'] ?? '')
        .toString()
        .padLeft(8, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text('Rincian Pembayaran'),
        backgroundColor: Color(0xFFE7B789),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            tooltip: 'Simpan PDF',
            onPressed: () => _saveToGallery(context),
          ),
        ],
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
                        formatter.format(jumlah), // Use the converted amount
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
                      nomorPembayaran,
                    ),
                    _buildInfoRow(
                      'Tanggal\nPembayaran',
                      DateFormat('dd MMMM yyyy').format(
                        DateTime.parse(transaksi['tanggal'] ?? DateTime.now().toString()),
                      ),
                    ),
                    _buildInfoRow(
                      'Pembayaran\nMelalui',
                      transaksi['metode_pembayaran'] ?? 'Tidak diketahui',
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

// Helper method for PDF info rows
pw.Widget _buildPdfInfoRow(String label, String value) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(vertical: 8),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.grey400,
              fontSize: 14,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}