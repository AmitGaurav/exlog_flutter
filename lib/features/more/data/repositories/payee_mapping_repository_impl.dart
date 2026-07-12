import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/payee_mapping.dart';
import '../../domain/repositories/payee_mapping_repository.dart';

class PayeeMappingRepositoryImpl implements PayeeMappingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PayeeMappingRepositoryImpl({
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
      _firestore.collection('payeeMappings');

  @override
  Future<List<PayeeMapping>> getMappings() async {
    final snapshot = await _col.where('userId', isEqualTo: _uid).get();
    final mappings = snapshot.docs.map(PayeeMapping.fromFirestore).toList();
    mappings.sort((a, b) => a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase()));
    return mappings;
  }

  @override
  Future<String> createMapping(PayeeMapping mapping) async {
    final docRef = await _col.add(mapping.copyWith(updatedAt: DateTime.now()).toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateMapping(PayeeMapping mapping) async {
    if (mapping.id == null) throw ArgumentError('PayeeMapping id must not be null');
    await _col.doc(mapping.id).update(mapping.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  @override
  Future<void> deleteMapping(String mappingId) => _col.doc(mappingId).delete();
}
