import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(_uid);

  @override
  Future<UserProfile> getProfile() async {
    final snapshot = await _doc.get();
    return UserProfile.fromFirestore(snapshot);
  }

  @override
  Future<void> updatePreferredCurrency(String currencyCode) =>
      _doc.set({'preferredCurrency': currencyCode}, SetOptions(merge: true));

  @override
  Future<void> updateAIParserConfig(AIParserConfig config) =>
      _doc.set({'aiParserConfig': config.toMap()}, SetOptions(merge: true));

  @override
  Future<void> updateSelfNames(List<String> selfNames) =>
      _doc.set({'selfNames': selfNames}, SetOptions(merge: true));
}
