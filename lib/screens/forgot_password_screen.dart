import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/data/services/auth_service.dart'; // Tambahkan import

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService(); // Gunakan AuthService
  bool _isLoading = false;
  bool _emailSent = false;
  final _formKey = GlobalKey<FormState>();
  
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Gunakan method yang sudah diperbaiki
      await _authService.sendPasswordResetEmail(_emailController.text);
      
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text('Lupa Password', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xFFE7B789),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: _emailSent ? _buildSuccessView() : _buildRequestForm(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Image.asset(
            'assets/images/logo_kos.png', // Pastikan menambahkan gambar ini di assets
            height: 180,
          ),
          SizedBox(height: 30),
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A2F1C),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Masukkan alamat email Anda untuk menerima link reset password',
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'contoh@email.com',
              prefixIcon: Icon(Icons.email, color: Color(0xFF4A2F1C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFFE7B789), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFF4A2F1C), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          SizedBox(height: 40),
          Container(
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Color(0xFF4A2F1C), Color(0xFF8B4513)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4A2F1C).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'KIRIM LINK RESET',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40),
        Image.asset(
          'assets/images/email_sent.png', // Make sure to add this to your assets
          height: 180,
        ),
        SizedBox(height: 40),
        Text(
          'Email Terkirim!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A2F1C),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          'Kami telah mengirimkan link reset password ke email ${_emailController.text}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.brown[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          'Silakan cek inbox dan folder spam email Anda. Klik link yang dikirimkan untuk melakukan reset password melalui halaman website kami.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.brown[400],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          'Melalui link tersebut, Anda akan diarahkan ke website KosSidoRame12 untuk mengatur password baru Anda.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.brown[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Color(0xFF4A2F1C), Color(0xFF8B4513)],
            ),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'KEMBALI KE LOGIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}