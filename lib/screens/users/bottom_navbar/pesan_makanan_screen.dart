import 'package:flutter/material.dart';
import 'package:proyekkos/screens/users/menu_list_screen.dart';

class PesanMakananScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header dengan logo dan nama user
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 50),
            
            child: Row(
              children: [
                Spacer(),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/dashboard_icon/verifikasi_pembayaran.png',
                      width: 50,
                      height: 50,
                    ),
                    SizedBox(width: 16),
                    Image.asset(
                      'assets/images/troli.png',
                      width: 50,
                      height: 50,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Body content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Makanan Card
                  _buildMenuCard(
                    context: context,
                    title: 'Makanan',
                    imagePath: 'assets/images/pesanmakan.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuListScreen(
                            kategori: 'makanan',
                            title: 'Makanan',
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 30),
                  // Minuman Card
                  _buildMenuCard(
                    context: context,
                    title: 'Minuman',
                    imagePath: 'assets/images/pesanmakan.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuListScreen(
                            kategori: 'minuman',
                            title: 'Minuman',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                imagePath,
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 