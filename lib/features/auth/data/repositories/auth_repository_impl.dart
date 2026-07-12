import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _functions = functions,
        _firestore = firestore;

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user == null ? null : _toAppUser(user));

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _toAppUser(credential.user!);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(displayName.trim());

    // Create user document in Firestore — shared schema with iOS app.
    await _firestore.collection('users').doc(credential.user!.uid).set(
      {
        'uid': credential.user!.uid,
        'email': email.trim(),
        'displayName': displayName.trim(),
        'isEmailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'android',
      },
      SetOptions(merge: true),
    );

    return _toAppUser(credential.user!);
  }

  @override
  Future<void> sendEmailVerificationCode() async {
    final callable = _functions.httpsCallable('sendEmailVerificationCode');
    await callable.call<dynamic>({});
  }

  @override
  Future<void> verifyEmailCode({required String code}) async {
    final callable = _functions.httpsCallable('verifyEmailCode');
    await callable.call<dynamic>({'code': code});
    // Reload token so emailVerified flag is fresh.
    await _auth.currentUser?.reload();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('Unable to verify account. Please sign out and sign in again.');
    }
    final credential = EmailAuthProvider.credential(email: email, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> deleteAccount() async {
    final callable = _functions.httpsCallable('deleteUserAccount');
    await callable.call<dynamic>();
    await _auth.signOut();
  }

  AppUser _toAppUser(User user) => AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        isEmailVerified: user.emailVerified,
      );
}
