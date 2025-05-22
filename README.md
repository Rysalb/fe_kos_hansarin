# Aplikasi Manajemen Kos

Aplikasi manajemen kos adalah solusi digital untuk mengelola operasional kos secara efisien. Aplikasi ini terdiri dari dua platform: backend menggunakan Laravel dan frontend menggunakan Flutter.

## Fitur Utama

### Untuk Pengelola Kos
- Manajemen akun admin
- Pengelolaan data kamar (CRUD)
- Verifikasi identitas penyewa
- Sistem pembukuan (pemasukan/pengeluaran)
- Verifikasi pembayaran sewa
- Pengelolaan katalog makanan
- Manajemen nomor penting
- Sistem notifikasi real-time
- Laporan keuangan

### Untuk Penyewa
- Pemesanan kamar
- Registrasi dan login
- Informasi penghuni kamar
- Pembayaran sewa online
- Riwayat pembayaran
- Pemesanan makanan
- Akses nomor penting
- Chat dengan pengelola via WhatsApp
- Notifikasi status pembayaran/pesanan

## Teknologi yang Digunakan

### Backend
- Laravel 10.x
- PHP 8.x
- MySQL
- RESTful API
- JWT Authentication

### Frontend
- Flutter
- BLoC Pattern
- GetX
- Provider
- Shared Preferences

## Persyaratan Sistem

### Backend
- PHP >= 8.1
- Composer
- MySQL >= 5.7
- Node.js & NPM
- Web Server (Apache/Nginx)

### Frontend
- Flutter SDK
- Android Studio / VS Code
- Android SDK
- iOS SDK (untuk pengembangan iOS)

## Instalasi

### Backend
1. Clone repository
```bash
git clone [url-repository]
```

2. Install dependencies
```bash
composer install
```

3. Setup environment
```bash
cp .env.example .env
php artisan key:generate
```

4. Konfigurasi database di .env
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nama_database
DB_USERNAME=username
DB_PASSWORD=password
```

5. Jalankan migrasi
```bash
php artisan migrate
php artisan db:seed
```

6. Jalankan server
```bash
php artisan serve
```

### Frontend
1. Install Flutter SDK
2. Clone repository frontend
3. Install dependencies
```bash
flutter pub get
```
4. Jalankan aplikasi
```bash
flutter run
```
