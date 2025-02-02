import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigasi ke halaman dashboard setelah 3 detik
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            // Expanded pertama untuk mendorong logo ke tengah
            Expanded(child: SizedBox()),
            // Gambar logo
            Image.asset(
              'assets/images/logo_kos.png',
              width: 200,
              height: 200,
            ),
            // Expanded kedua untuk ruang antara logo dan text
            Expanded(child: SizedBox()),
            // Tagline aplikasi di bagian bawah
            Padding(
              padding: EdgeInsets.only(bottom: 64.0),
              child: Text(
                'Kelola Kos Menjadi Lebih Mudah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}