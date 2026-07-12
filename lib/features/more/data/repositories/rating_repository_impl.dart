import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_rating.dart';
import '../../domain/repositories/rating_repository.dart';

class RatingRepositoryImpl implements RatingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RatingRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('appRatings');

  @override
  Future<AppRating?> getMyRating() async {
    final snapshot = await _col.where('userId', isEqualTo: _uid).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return AppRating.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<AppRating> submitRating(AppRating rating) async {
    if (rating.id != null) {
      await _col.doc(rating.id).set(rating.toFirestore(), SetOptions(merge: true));
      return rating;
    }
    final docRef = await _col.add(rating.toFirestore());
    return rating.copyWith(id: docRef.id);
  }

  @override
  Future<List<AppRating>> getAllRatings() async {
    final snapshot = await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(AppRating.fromFirestore).toList();
  }

  @override
  Future<RatingStatistics> getStatistics() async {
    final ratings = await getAllRatings();
    if (ratings.isEmpty) return RatingStatistics.empty;

    var sum = 0;
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in ratings) {
      sum += r.rating;
      if (counts.containsKey(r.rating)) counts[r.rating] = counts[r.rating]! + 1;
    }

    return RatingStatistics(
      totalRatings: ratings.length,
      averageRating: sum / ratings.length,
      fiveStarCount: counts[5]!,
      fourStarCount: counts[4]!,
      threeStarCount: counts[3]!,
      twoStarCount: counts[2]!,
      oneStarCount: counts[1]!,
    );
  }
}
