import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

enum UserProfileStatus { initial, loading, success, failure }

class UserProfileState extends Equatable {
  final UserProfileStatus status;
  final UserProfile? profile;
  final String? error;

  const UserProfileState({
    this.status = UserProfileStatus.initial,
    this.profile,
    this.error,
  });

  bool get isAdmin => profile?.premiumTier == PremiumTier.admin;

  UserProfileState copyWith({
    UserProfileStatus? status,
    UserProfile? profile,
    String? error,
    bool clearError = false,
  }) =>
      UserProfileState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, profile, error];
}
