import 'package:flutter/material.dart';

class NotifikasiScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFE7B789),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: 8, // Sesuaikan dengan jumlah notifikasi yang ada
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    index < 4
                        ? 'Kamar ${index + 1} Segera lakukan pembayaran sewa kos'
                        : index < 6
                            ? 'Verifikasi Pembayaran kamar ${index + 1}'
                            : 'Kamar ${index - 4} Melakukan Pemesanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '29 September 2024',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    // Tambahkan logika ketika notifikasi ditekan
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 