import 'package:equatable/equatable.dart';

import '../../domain/entities/app_rating.dart';

enum RatingStatus { initial, loading, success, failure }

class RatingState extends Equatable {
  final RatingStatus status;
  final AppRating? myRating;
  final bool justSubmitted;
  final String? error;

  const RatingState({
    this.status = RatingStatus.initial,
    this.myRating,
    this.justSubmitted = false,
    this.error,
  });

  RatingState copyWith({
    RatingStatus? status,
    AppRating? myRating,
    bool? justSubmitted,
    String? error,
    bool clearError = false,
  }) =>
      RatingState(
        status: status ?? this.status,
        myRating: myRating ?? this.myRating,
        justSubmitted: justSubmitted ?? false,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, myRating, justSubmitted, error];
}
