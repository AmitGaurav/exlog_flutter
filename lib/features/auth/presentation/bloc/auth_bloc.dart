import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<dynamic> _authSubscription;

  AuthBloc(this._authRepository) : super(const AuthState()) {
    // Listen to Firebase auth state changes and dispatch internally.
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(AuthUserChanged(user)),
    );

    on<AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSendVerificationCodeRequested>(_onSendCode);
    on<AuthVerifyEmailCodeRequested>(_onVerifyCode);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthSignOutRequested>(_onSignOut);
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    } else if (!user.isEmailVerified) {
      emit(state.copyWith(
        status: AuthStatus.emailVerificationRequired,
        user: user,
        pendingEmail: user.email,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      ));
    }
  }

  Future<void> _onSignIn(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      await _authRepository.signIn(email: event.email, password: event.password);
      // authStateChanges stream fires → _onUserChanged handles navigation.
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      ));
    }
  }

  Future<void> _onSignUp(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      await _authRepository.sendEmailVerificationCode();
      emit(state.copyWith(
        status: AuthStatus.emailVerificationRequired,
        user: user,
        pendingEmail: event.email,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      ));
    }
  }

  Future<void> _onSendCode(
    AuthSendVerificationCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      await _authRepository.sendEmailVerificationCode();
      emit(state.copyWith(status: AuthStatus.emailVerificationRequired));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      ));
    }
  }

  Future<void> _onVerifyCode(
    AuthVerifyEmailCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      await _authRepository.verifyEmailCode(code: event.code);
      // Reload current user after verification.
      final updated = _authRepository.currentUser;
      emit(state.copyWith(status: AuthStatus.authenticated, user: updated));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      ));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      await _authRepository.sendPasswordResetEmail(email: event.email);
      emit(state.copyWith(
        status: AuthStatus.success,
        errorMessage: 'Password reset email sent. Check your inbox.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: _mapFirebaseError(e),
      ));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  String _mapFirebaseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential') ||
        msg.contains('invalid-email')) {
      return 'Invalid email or password. Please try again.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('weak-password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (msg.contains('network')) {
      return 'Network error. Check your internet connection.';
    }
    if (msg.contains('permission-denied') || msg.contains('insufficient permissions')) {
      return 'Verification failed: insufficient permissions. Error code: 7';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
