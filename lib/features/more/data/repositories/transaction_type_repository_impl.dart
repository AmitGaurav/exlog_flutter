import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/transaction_type_model.dart';
import '../../domain/repositories/transaction_type_repository.dart';

class TransactionTypeRepositoryImpl implements TransactionTypeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionTypeRepositoryImpl({
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
      _firestore.collection('transactionTypes');

  @override
  Future<List<TransactionTypeModel>> getTypes() async {
    final snapshot = await _col.where('userId', isEqualTo: _uid).get();
    if (snapshot.docs.isEmpty) {
      return _seedDefaults();
    }
    final types = snapshot.docs.map(TransactionTypeModel.fromFirestore).toList();
    types.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return types;
  }

  Future<List<TransactionTypeModel>> _seedDefaults() async {
    final defaults = TransactionTypeModel.defaults(_uid);
    final batch = _firestore.batch();
    final seeded = <TransactionTypeModel>[];
    for (final type in defaults) {
      final docRef = _col.doc();
      batch.set(docRef, type.toFirestore());
      seeded.add(type.copyWith(id: docRef.id));
    }
    await batch.commit();
    return seeded;
  }

  @override
  Future<String> createType(TransactionTypeModel type) async {
    final docRef = await _col.add(type.copyWith(updatedAt: DateTime.now()).toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateType(TransactionTypeModel type) async {
    if (type.id == null) throw ArgumentError('TransactionTypeModel id must not be null');
    await _col.doc(type.id).update(type.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  @override
  Future<void> deleteType(String typeId) => _col.doc(typeId).delete();
}
