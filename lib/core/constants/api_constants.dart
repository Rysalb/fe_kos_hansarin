class ApiConstants {
  // Untuk vercel
  static const String baseUrl = 'backend-kost-sidorame12.vercel.app/api';
  static const String baseUrlStorage = 'backend-kost-sidorame12.vercel.app';
  static const String baseUrlimage = 'backend-kost-sidorame12.vercel.app';
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

  // Untuk Android Emulator
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrlStorage = 'http://10.0.2.2:8000';
  // static const String baseUrlimage = 'http://10.0.2.2:8000';

// class ApiConstants {
//   // For debugging using localhost
//   static const String baseUrl = 'http://127.0.0.1:8000/api';
//   static const String baseUrlStorage = 'http://127.0.0.1:8000';
//   static const String baseUrlimage = 'http://127.0.0.1:8000';

//   static String getImageUrl(String? path) {
//     if (path == null || path.isEmpty) return '';
//     final cleanPath = path.startsWith('/') ? path.substring(1) : path;
//     return '$baseUrlimage/storage/$cleanPath';
//   }
// }

//for local development
// class ApiConstants {
//   // Use your computer's local IP address
//   static const String baseUrl = 'http://192.168.17.170:8000/api'; // Replace x with your IP
//   static const String baseUrlStorage = 'http://192.168.17.170:8000';
//   static const String baseUrlimage = 'http://192.168.17.170:8000';

//   static String getImageUrl(String? path) {
//     if (path == null || path.isEmpty) return '';
//     final cleanPath = path.startsWith('/') ? path.substring(1) : path;
//     return '$baseUrlimage/storage/$cleanPath';
//   }
// }