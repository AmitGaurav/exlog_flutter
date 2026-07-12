import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Emits [AppUser] when signed-in, null when signed-out.
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Calls the Firebase `sendEmailVerificationCode` callable function
  /// which sends a 6-digit OTP (same as iOS app).
  Future<void> sendEmailVerificationCode();

  /// Calls the Firebase `verifyEmailCode` callable function.
  Future<void> verifyEmailCode({required String code});

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  /// Re-authenticates with [currentPassword] then updates to [newPassword].
  /// Only meaningful for email/password accounts.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Calls the shared `deleteUserAccount` Cloud Function (same one the iOS
  /// app uses) to purge all user data, then signs out.
  Future<void> deleteAccount();
}
