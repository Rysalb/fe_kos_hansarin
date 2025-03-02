import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyekkos/data/services/notification_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'data/services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/users/dashboard_page.dart';
import 'screens/admin/verif_pembayaran/verifikasi_pembayaran_screen.dart';
import 'screens/admin/kelola_penyewa/verifikasi_penyewa.dart';
import 'screens/admin/notifikasi/notifikasi_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final AuthService authService = AuthService();
  final NotificationService notificationService;
  
  MyApp({required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authService: authService,
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: notificationService.navigatorKey,
        title: 'Kos App',
        theme: ThemeData(primarySwatch: Colors.brown),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginPage(),
          '/admin/dashboard': (context) => AdminDashboardPage(),
          '/dashboard': (context) => DashboardPage(),
          '/admin/verifikasi-pembayaran': (context) => VerifikasiPembayaranScreen(),
          '/admin/verifikasi-penyewa': (context) => VerifikasiPenyewaScreen(),
          '/admin/notifikasi': (context) => NotifikasiScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class User {
  final String role;
  User({required this.role});
}

// When user logs in, set their user_id as a tag for targeting
Future<void> setUserIdTagInOneSignal(String userId) async {
  try {
    await OneSignal.User.addTagWithKey('user_id', userId);
    print('User ID tag set: $userId');
  } catch (e) {
    print('Error setting user ID tag: $e');
  }
}

// Call this when you handle successful login
void onLoginSuccess(User user, String userId) {
  // Set role tag
  if (user.role == 'admin') {
    OneSignal.User.addTagWithKey('role', 'admin');
  } else {
    OneSignal.User.addTagWithKey('role', 'user');
  }
  
  // Set user ID tag for specific targeting
  setUserIdTagInOneSignal(userId);
  
  // Save to SharedPreferences
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString('user_role', user.role);
  });
}
