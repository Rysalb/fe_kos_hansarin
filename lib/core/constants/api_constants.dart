class ApiConstants {
  // Untuk Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String baseUrlimage = 'http://10.0.2.2:8000';
  // Untuk iOS Simulator
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Untuk debugging
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    // Hapus leading slash jika ada
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrlimage/storage/ktp/$cleanPath';
  }
}