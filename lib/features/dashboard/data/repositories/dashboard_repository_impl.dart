import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/period_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DashboardRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    return uid;
  }

  @override
  Future<PeriodSummary> getMonthSummary({required String period}) async {
    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('summaries_monthly')
        .doc(period)
        .get();

    if (!doc.exists || doc.data() == null) {
      return PeriodSummary.empty;
    }
    return PeriodSummary.fromFirestore(period, doc.data()!);
  }

  @override
  Future<PeriodSummary> getYearSummary({required String year}) async {
    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('summaries_yearly')
        .doc(year)
        .get();

    if (!doc.exists || doc.data() == null) {
      return PeriodSummary.empty;
    }
    return PeriodSummary.fromFirestore(year, doc.data()!);
  }
}
