import 'package:flutter/material.dart';
import 'package:proyekkos/screens/login.dart';
import 'package:proyekkos/data/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationSuccessPage extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();
  
  // Function to send notification to admin when "Mengerti" button is clicked
  Future<void> _sendNotificationToAdmin(BuildContext context) async {
    try {
      // Get user information from SharedPreferences if available
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('register_name') ?? 'Calon penyewa baru';
      final userUnit = prefs.getString('register_unit') ?? 'belum ditentukan';
      
      // Send notification to all admins
      await _notificationService.sendNotificationToAdmins(
        title: 'Pendaftaran Penyewa Baru',
        message: 'Penyewa baru $userName telah mendaftar untuk unit $userUnit dan menunggu verifikasi',
        type: 'tenant_verification',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'target_role': 'admin',
          'notification_source': 'registration_success',
        },
      );
      
      print('Registration notification sent to admins');
      
      // Navigate to login page after sending notification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error sending registration notification: $e');
      // Still navigate to login page even if notification fails
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 120),
              Image.asset(
                'assets/images/verif.png',
                width: 120,
                height: 120,
              ),
              SizedBox(height: 32),
              Text(
                'Terimakasih telah melakukan registrasi, selanjutnya data anda akan di verifikasi oleh pengelola kos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Hasil Verifikasi akan dikirimkan melalui nomor WhatsApp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // Update the onPressed callback to send notification
                  onPressed: () => _sendNotificationToAdmin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A2F1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Mengerti',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}