import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/rating_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;
  final RatingRepository _ratingRepository;

  AdminBloc(this._adminRepository, this._ratingRepository) : super(const AdminState()) {
    on<AdminLoadRequested>(_onLoad);
    on<AdminUserSearchChanged>((event, emit) => emit(state.copyWith(searchQuery: event.query)));
    on<AdminToggleUserActiveRequested>(_onToggleActive);
    on<AdminSetPremiumTierRequested>(_onSetPremiumTier);
  }

  Future<void> _onLoad(
    AdminLoadRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(state.copyWith(status: AdminStatus.loading, clearError: true));
    try {
      final stats = await _adminRepository.getStatistics();
      final users = await _adminRepository.getAllUsers();
      final ratingStats = await _ratingRepository.getStatistics();
      final recentRatings = await _ratingRepository.getAllRatings();
      emit(state.copyWith(
        status: AdminStatus.success,
        stats: stats,
        users: users,
        ratingStats: ratingStats,
        recentRatings: recentRatings.take(5).toList(),
      ));
    } catch (_) {
      emit(state.copyWith(status: AdminStatus.failure, error: 'Failed to load admin data.'));
    }
  }

  Future<void> _onToggleActive(
    AdminToggleUserActiveRequested event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminRepository.setUserActive(event.uid, event.isActive);
      final updated = state.users
          .map((u) => u.uid == event.uid
              ? AdminUserSummary(
                  uid: u.uid,
                  email: u.email,
                  displayName: u.displayName,
                  createdAt: u.createdAt,
                  premiumTier: u.premiumTier,
                  isActive: event.isActive,
                )
              : u)
          .toList();
      emit(state.copyWith(users: updated, successMessage: 'User status updated', clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update user status.'));
    }
  }

  Future<void> _onSetPremiumTier(
    AdminSetPremiumTierRequested event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _adminRepository.setPremiumTier(event.uid, event.tier);
      final updated = state.users
          .map((u) => u.uid == event.uid
              ? AdminUserSummary(
                  uid: u.uid,
                  email: u.email,
                  displayName: u.displayName,
                  createdAt: u.createdAt,
                  premiumTier: event.tier,
                  isActive: u.isActive,
                )
              : u)
          .toList();
      final message = event.tier == PremiumTier.free ? 'Premium revoked' : 'Premium granted successfully';
      emit(state.copyWith(users: updated, successMessage: message, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update premium tier.'));
    }
  }
}
