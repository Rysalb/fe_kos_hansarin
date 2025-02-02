import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'data/repositories/auth_repository.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/admin_dashboard.dart';
import 'screens/dashboard_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final authRepository = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: authRepository,
          ),
        ),
        // Tambahkan BLoC provider lainnya di sini
      ],
      child: MaterialApp(
        title: 'Kos App',
        theme: ThemeData(primarySwatch: Colors.brown),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginPage(),
          '/admin/dashboard': (context) => AdminDashboardPage(),
          '/dashboard': (context) => DashboardPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
