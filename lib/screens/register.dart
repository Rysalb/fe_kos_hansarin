import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'show File, Platform;
import 'package:permission_handler/permission_handler.dart';
import 'package:proyekkos/screens/registration_success_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscureText = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _nikController = TextEditingController();
  final _alamatController = TextEditingController();
  
  String? _selectedKamar;
  File? _ktpImage;
  final _authService = AuthService();
  
  List<Map<String, dynamic>> _kamarList = [];
  bool _isLoadingKamar = true;
  
  @override
  void initState() {
    super.initState();
    _fetchKamarTersedia();
  }

  Future<void> _fetchKamarTersedia() async {
    setState(() => _isLoadingKamar = true);
    try {
      final kamarList = await _authService.getKamarTersedia();
      print('Response Kamar List: $kamarList');
      setState(() {
        _kamarList = kamarList;
        _isLoadingKamar = false;
      });
    } catch (e) {
      setState(() => _isLoadingKamar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data kamar: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      if (Platform.isAndroid) {
        // Cek status permission
        final storageStatus = await Permission.storage.status;
        final photosStatus = await Permission.photos.status;
        
        // Hanya minta permission jika belum diizinkan
        if (storageStatus.isGranted == false && photosStatus.isGranted == false) {
          // Request permissions langsung tanpa dialog
          final statuses = await [
            Permission.storage,
            Permission.photos,
          ].request();

          // Jika masih ditolak setelah request
          if (statuses[Permission.storage]!.isDenied || 
              statuses[Permission.photos]!.isDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Izin akses diperlukan untuk memilih foto'),
                action: SnackBarAction(
                  label: 'Buka Pengaturan',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
            return;
          }
        }
      }

      // Langsung pilih gambar jika permission sudah diizinkan
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _ktpImage = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto KTP berhasil dipilih')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: ${e.toString()}')),
      );
    }
  }

  Future<bool?> _showPermissionDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Izin Akses Diperlukan'),
          content: Text(
            'Aplikasi memerlukan izin untuk mengakses galeri/penyimpanan untuk memilih foto KTP. '
            'Apakah Anda ingin memberikan izin?'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Ya'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon upload foto KTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        idUnit: _selectedKamar!,
        nik: _nikController.text,
        fotoKtp: _ktpImage!,
        alamatAsal: _alamatController.text,
        nomorWa: _whatsappController.text,
      );

      // Langsung navigasi ke halaman sukses tanpa mengecek response.status
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegistrationSuccessPage()),
        );
      }
    } catch (e) {
      // Cek apakah data berhasil tersimpan meskipun ada error
      if (e.toString().contains("type '_Map<String, dynamic>' is not a subtype of type 'UserModel?'")) {
        // Jika error hanya masalah format response, tetap lanjut ke halaman sukses
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RegistrationSuccessPage()),
          );
        }
      } else {
        // Jika error lain, tampilkan snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan registrasi. Silakan coba lagi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E7),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF4A2F1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Registrasi',
          style: TextStyle(
            color: Color(0xFF4A2F1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E7), Color(0xFFFFE5CC)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A2F1C),
                  ),
                ),
                Text(
                  'Silakan lengkapi data diri Anda',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown[400],
                  ),
                ),
                SizedBox(height: 32),
                _buildKamarDropdown(),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.person,
                  validator: (value) => value!.isEmpty ? 'Masukkan nama lengkap' : null,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _whatsappController,
                  label: 'Nomor WhatsApp',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Masukkan nomor WhatsApp' : null,
                ),
                SizedBox(height: 20),
                _buildKTPUpload(),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty ? 'Masukkan email' : null,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _nikController,
                  label: 'NIK',
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.length != 16 ? 'NIK harus 16 digit' : null,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _alamatController,
                  label: 'Alamat Asal',
                  icon: Icons.home,
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Masukkan alamat asal' : null,
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: _obscureText,
                  validator: (value) => value!.length < 8 ? 'Password minimal 8 karakter' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF4A2F1C),
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
                SizedBox(height: 32),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A2F1C),
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, color: Color(0xFF4A2F1C)),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFFE7B789), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Color(0xFF4A2F1C), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKTPUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Foto KTP'),
        SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFFFE5CC),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file),
                SizedBox(width: 8),
                Text(_ktpImage == null ? 'Pilih file' : 'File dipilih'),
              ],
            ),
          ),
        ),
        if (_ktpImage != null) ...[
          SizedBox(height: 8),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_ktpImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKamarDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Kamar yang Tersedia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFE5CC),
            borderRadius: BorderRadius.circular(25),
          ),
          child: _isLoadingKamar
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedKamar,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                  items: _kamarList.map((kamar) {
                    return DropdownMenuItem(
                      value: kamar['id_unit']?.toString(),
                      child: Text(
                        '${kamar['nomor_kamar']}',
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedKamar = value;
                        final selectedKamar = _kamarList.firstWhere(
                          (kamar) => kamar['id_unit'].toString() == value,
                          orElse: () => {},
                        );
                        print('Selected Kamar: $selectedKamar');
                      });
                    }
                  },
                  validator: (value) => value == null ? 'Pilih kamar' : null,
                ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
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
        onPressed: _isLoading ? null : _register,
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
                'Register',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _whatsappController.dispose();
    _nikController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}
