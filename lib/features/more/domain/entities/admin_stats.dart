import 'package:equatable/equatable.dart';

import 'user_profile.dart';

class AdminStats extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int premiumUsers;
  final int freeUsers;
  final int lifetimeUsers;
  final int yearlyUsers;
  final int monthlyUsers;
  final double conversionRate;

  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.premiumUsers,
    required this.freeUsers,
    required this.lifetimeUsers,
    required this.yearlyUsers,
    required this.monthlyUsers,
    required this.conversionRate,
  });

  static const empty = AdminStats(
    totalUsers: 0,
    activeUsers: 0,
    premiumUsers: 0,
    freeUsers: 0,
    lifetimeUsers: 0,
    yearlyUsers: 0,
    monthlyUsers: 0,
    conversionRate: 0,
  );

  @override
  List<Object?> get props =>
      [totalUsers, activeUsers, premiumUsers, freeUsers, lifetimeUsers, yearlyUsers, monthlyUsers, conversionRate];
}

/// Summary row for the admin user list — a lighter view of [UserProfile]
/// that doesn't require the full doc read used for the detail sheet.
class AdminUserSummary extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final DateTime createdAt;
  final PremiumTier premiumTier;
  final bool isActive;

  const AdminUserSummary({
    required this.uid,
    this.email,
    this.displayName,
    required this.createdAt,
    required this.premiumTier,
    required this.isActive,
  });

  bool get isPremium => premiumTier.isPremium;

  String get statusBadge {
    if (!isActive) return 'Inactive';
    switch (premiumTier) {
      case PremiumTier.lifetime:
        return 'Lifetime';
      case PremiumTier.yearly:
        return 'Yearly';
      case PremiumTier.monthly:
        return 'Monthly';
      case PremiumTier.admin:
        return 'Admin';
      case PremiumTier.free:
        return 'Free';
    }
  }

  @override
  List<Object?> get props => [uid, email, displayName, createdAt, premiumTier, isActive];
}
