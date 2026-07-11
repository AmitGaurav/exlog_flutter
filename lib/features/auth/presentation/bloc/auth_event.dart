import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired internally when Firebase auth state changes.
class AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthSendVerificationCodeRequested extends AuthEvent {
  const AuthSendVerificationCodeRequested();
}

class AuthVerifyEmailCodeRequested extends AuthEvent {
  final String code;
  const AuthVerifyEmailCodeRequested({required this.code});

  @override
  List<Object?> get props => [code];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
