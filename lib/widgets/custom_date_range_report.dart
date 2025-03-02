import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:proyekkos/data/services/pemasukan_pengeluaran_service.dart';

class CustomDateRangeReport extends StatelessWidget {
  final IconData icon;
  final PemasukanPengeluaranService _service = PemasukanPengeluaranService();

  CustomDateRangeReport({
    Key? key,
    this.icon = Icons.summarize,
  }) : super(key: key);

  Future<void> _showDateRangeDialog(BuildContext context) async {
    DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFE7B789),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      await _generateReport(context, pickedDateRange);
    }
  }

  Future<void> _generateReport(BuildContext context, DateTimeRange dateRange) async {
    try {
      // Get transactions for date range
      final startDate = dateRange.start;
      final endDate = dateRange.end;
      
      // Format dates for display
      final dateFormatter = DateFormat('dd MMMM yyyy');
      final currencyFormatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      // Create PDF document
      final pdf = pw.Document();

      // Load logo
      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo_kos.png')).buffer.asUint8List(),
      );

      // Get transactions and calculate totals
      final transaksi = await _service.getAllTransaksi();
      double totalPemasukan = 0;
      double totalPengeluaran = 0;

      // Filter transactions by date range and calculate totals
      final filteredTransaksi = transaksi.where((item) {
        final tanggal = DateTime.parse(item['tanggal']);
        return tanggal.isAfter(startDate.subtract(Duration(days: 1))) && 
               tanggal.isBefore(endDate.add(Duration(days: 1)));
      }).toList();

      // Calculate totals
      for (var item in filteredTransaksi) {
        final jumlah = double.parse(item['jumlah'].toString());
        if (item['jenis_transaksi'] == 'pemasukan') {
          totalPemasukan += jumlah;
        } else {
          totalPengeluaran += jumlah;
        }
      }

      // Add page to PDF
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header with logo
                  pw.Center(
                    child: pw.Image(imageLogo, width: 80, height: 80),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Center(
                    child: pw.Text(
                      'Laporan Keuangan',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  
                  // Summary section
                  pw.Container(
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        _buildPdfSummaryRow('Total Pemasukan', currencyFormatter.format(totalPemasukan)),
                        _buildPdfSummaryRow('Total Pengeluaran', currencyFormatter.format(totalPengeluaran)),
                        pw.Divider(),
                        _buildPdfSummaryRow('Saldo', currencyFormatter.format(totalPemasukan - totalPengeluaran)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // Transactions list
                  pw.Text(
                    'Detail Transaksi:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...filteredTransaksi.map((transaksi) {
                    final isIncome = transaksi['jenis_transaksi'] == 'pemasukan';
                    final jumlah = double.parse(transaksi['jumlah'].toString());
                    final tanggal = DateFormat('dd/MM/yyyy').format(
                      DateTime.parse(transaksi['tanggal'])
                    );

                    return pw.Container(
                      margin: pw.EdgeInsets.only(bottom: 8),
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(transaksi['kategori'] ?? 'Tidak ada kategori'),
                                pw.Text(
                                  transaksi['keterangan'] ?? '-',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                                pw.Text(
                                  tanggal,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          pw.Text(
                            currencyFormatter.format(jumlah),
                            style: pw.TextStyle(
                              color: isIncome ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      );

      // Share/save PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'laporan_keuangan_${DateFormat('dd-MM-yyyy').format(startDate)}_${DateFormat('dd-MM-yyyy').format(endDate)}.pdf',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat laporan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _showDateRangeDialog(context),
      tooltip: 'Buat Laporan',
    );
  }
}

// Helper method for PDF summary rows
pw.Widget _buildPdfSummaryRow(String label, String value) {
  return pw.Padding(
    padding: pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value),
      ],
    ),
  );
}