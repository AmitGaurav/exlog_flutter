import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/app_rating.dart';

enum AdminStatus { initial, loading, success, failure }

class AdminState extends Equatable {
  final AdminStatus status;
  final AdminStats stats;
  final RatingStatistics ratingStats;
  final List<AppRating> recentRatings;
  final List<AdminUserSummary> users;
  final String searchQuery;
  final String? error;
  final String? successMessage;

  const AdminState({
    this.status = AdminStatus.initial,
    this.stats = AdminStats.empty,
    this.ratingStats = RatingStatistics.empty,
    this.recentRatings = const [],
    this.users = const [],
    this.searchQuery = '',
    this.error,
    this.successMessage,
  });

  List<AdminUserSummary> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    final q = searchQuery.toLowerCase();
    return users
        .where((u) =>
            (u.email?.toLowerCase().contains(q) ?? false) ||
            (u.displayName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  AdminState copyWith({
    AdminStatus? status,
    AdminStats? stats,
    RatingStatistics? ratingStats,
    List<AppRating>? recentRatings,
    List<AdminUserSummary>? users,
    String? searchQuery,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      AdminState(
        status: status ?? this.status,
        stats: stats ?? this.stats,
        ratingStats: ratingStats ?? this.ratingStats,
        recentRatings: recentRatings ?? this.recentRatings,
        users: users ?? this.users,
        searchQuery: searchQuery ?? this.searchQuery,
        error: clearError ? null : (error ?? this.error),
        successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      );

  @override
  List<Object?> get props =>
      [status, stats, ratingStats, recentRatings, users, searchQuery, error, successMessage];
}
