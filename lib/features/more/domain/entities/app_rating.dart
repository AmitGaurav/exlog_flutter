import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppRating extends Equatable {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppRating({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppRating.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppRating(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  AppRating copyWith({
    String? id,
    int? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppRating(
        id: id ?? this.id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, userId, userName, userEmail, rating, comment, createdAt, updatedAt];
}

class RatingStatistics extends Equatable {
  final int totalRatings;
  final double averageRating;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const RatingStatistics({
    required this.totalRatings,
    required this.averageRating,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  static const empty = RatingStatistics(
    totalRatings: 0,
    averageRating: 0,
    fiveStarCount: 0,
    fourStarCount: 0,
    threeStarCount: 0,
    twoStarCount: 0,
    oneStarCount: 0,
  );

  int countFor(int star) {
    switch (star) {
      case 5:
        return fiveStarCount;
      case 4:
        return fourStarCount;
      case 3:
        return threeStarCount;
      case 2:
        return twoStarCount;
      case 1:
        return oneStarCount;
      default:
        return 0;
    }
  }

  double percentFor(int star) {
    if (totalRatings == 0) return 0;
    return countFor(star) / totalRatings * 100;
  }

  @override
  List<Object?> get props =>
      [totalRatings, averageRating, fiveStarCount, fourStarCount, threeStarCount, twoStarCount, oneStarCount];
}
