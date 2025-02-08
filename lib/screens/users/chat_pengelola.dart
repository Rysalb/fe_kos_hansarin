import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/auth_service.dart';

class ChatPengelola extends StatefulWidget {
  @override
  _ChatPengelolaState createState() => _ChatPengelolaState();
}


class _ChatPengelolaState extends State<ChatPengelola> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _adminList = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminList();
  }

  Future<void> _loadAdminList() async {
    try {
      final admins = await _authService.getAdminList();
      setState(() {
        // Filter hanya admin yang memiliki nomor_wa
        _adminList = admins.where((admin) => 
          admin['nomor_wa'] != null && 
          admin['nomor_wa'].toString().isNotEmpty
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin list: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    try {
      // Format nomor telepon
      String formattedNumber = phoneNumber.startsWith('0') 
          ? '62${phoneNumber.substring(1)}' 
          : phoneNumber;
      
      // Buat URL WhatsApp
      final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$formattedNumber');
      final Uri webWhatsappUri = Uri.parse('https://wa.me/$formattedNumber');

      try {
        // Coba buka aplikasi WhatsApp
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('Error opening WhatsApp app, trying web version...');
        // Jika gagal, coba buka versi web
        if (await canLaunchUrl(webWhatsappUri)) {
          await launchUrl(
            webWhatsappUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
            );
          }
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: Text(
            'List Akun Pengelola',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Color(0xFFE7B789),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                // Tampilkan informasi jika diperlukan
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminList,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _adminList.length,
                itemBuilder: (context, index) {
                  final admin = _adminList[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Color(0xFFFFE5CC),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _launchWhatsApp(admin['nomor_wa']),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                admin['name'] ?? 'Pengelola',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4A2F1C),
                                ),
                              ),
                              Image.asset(
                                'assets/images/dashboard_icon/wa.png',
                                width: 24,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}