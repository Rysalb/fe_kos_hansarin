import 'package:flutter_bloc/flutter_bloc.dart';
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
        
        // Simpan token dan role
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('user_role', response['user']['role']);
        
        print('Token saved: ${response['token']}'); // Debugging
        print('Role saved: ${response['user']['role']}'); // Debugging
        
        final user = UserModel(
          id: response['user']['id_user'],
          name: response['user']['name'],
          email: response['user']['email'],
          role: response['user']['role'],
        );
        
        emit(AuthSuccess(user));
      } catch (e) {
        emit(AuthFailure(e.toString()));
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