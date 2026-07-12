import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_rating.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_event.dart';
import 'rating_state.dart';

class RatingBloc extends Bloc<RatingEvent, RatingState> {
  final RatingRepository _repository;
  final FirebaseAuth _auth;

  RatingBloc(this._repository, this._auth) : super(const RatingState()) {
    on<RatingLoadRequested>(_onLoad);
    on<RatingSubmitRequested>(_onSubmit);
  }

  Future<void> _onLoad(
    RatingLoadRequested event,
    Emitter<RatingState> emit,
  ) async {
    emit(state.copyWith(status: RatingStatus.loading, clearError: true));
    try {
      final rating = await _repository.getMyRating();
      emit(state.copyWith(status: RatingStatus.success, myRating: rating));
    } catch (_) {
      emit(state.copyWith(status: RatingStatus.failure, error: 'Failed to load your rating.'));
    }
  }

  Future<void> _onSubmit(
    RatingSubmitRequested event,
    Emitter<RatingState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(error: 'User not logged in'));
      return;
    }
    try {
      final now = DateTime.now();
      final existing = state.myRating;
      final rating = AppRating(
        id: existing?.id,
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userEmail: user.email ?? '',
        rating: event.rating,
        comment: event.comment.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      final saved = await _repository.submitRating(rating);
      emit(state.copyWith(status: RatingStatus.success, myRating: saved, justSubmitted: true, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to submit rating.'));
    }
  }
}
