import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:proyekkos/data/models/auth_response.dart';
import '../../data/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final UserModel user;
  AuthSuccess(this.user);
  
  @override
  List<Object> get props => [user];
}
class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
  
  @override
  List<Object> get props => [error];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.login(event.email, event.password);
        if (response.status) {
          emit(AuthSuccess(response.user!));
        } else {
          emit(AuthFailure(response.message));
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
} 