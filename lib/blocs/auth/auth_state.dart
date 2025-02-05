import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

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