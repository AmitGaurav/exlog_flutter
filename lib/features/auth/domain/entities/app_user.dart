import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final bool isEmailVerified;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isEmailVerified,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  /// First name for greetings (everything before the first space).
  String get firstName {
    final parts = displayName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : displayName;
  }

  @override
  List<Object?> get props => [uid, email, displayName, isEmailVerified];
}
