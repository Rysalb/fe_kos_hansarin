import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService}) 
      : _authService = authService ?? AuthService(),
        super(AuthInitial()) {
    
    on<LoginRequested>((event, emit) async {
      try {
        emit(AuthLoading());
        final response = await _authService.login(event.email, event.password);
        
        // Check status first
        if (!response['status']) {
          // Use error message from backend
          emit(AuthFailure(response['message'] ?? 'Terjadi kesalahan'));
          return;
        }
        
        // If login successful, save token and role
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('user_role', response['user']['role']);
        
        final user = UserModel(
          id: response['user']['id_user'],
          name: response['user']['name'],
          email: response['user']['email'],
          role: response['user']['role'],
        );

        // After successful login
        final userId = response['user']['id_user'].toString();
        // Set user_id tag for OneSignal
        await OneSignal.User.addTagWithKey('user_id', userId);
        // Set role tag
        await OneSignal.User.addTagWithKey('role', 'user');
        print('Set user tags: user_id=$userId, role=user');

        // Save to shared preferences for persistent storage
        await prefs.setString('user_id', userId);
        
        emit(AuthSuccess(user));
      } catch (e) {
        // Try to parse error message from response if available
        String errorMessage = 'Terjadi kesalahan pada server';
        if (e is Exception) {
          final message = e.toString();
          if (message.contains('Email yang Anda masukkan tidak terdaftar') ||
              message.contains('Password yang Anda masukkan salah') ||
              message.contains('Akun Anda masih dalam proses verifikasi admin') ||
              message.contains('Akun Anda telah ditolak oleh admin')) {
            errorMessage = message.replaceAll('Exception: ', '');
          }
        }
        emit(AuthFailure(errorMessage));
      }
    });

    on<LogoutRequested>((event, emit) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Hapus semua data tersimpan
        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}