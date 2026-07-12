import '../entities/app_rating.dart';

abstract interface class RatingRepository {
  Future<AppRating?> getMyRating();

  Future<AppRating> submitRating(AppRating rating);

  /// Admin-only: all ratings, newest first.
  Future<List<AppRating>> getAllRatings();

  /// Admin-only: aggregate stats across all ratings.
  Future<RatingStatistics> getStatistics();
}
