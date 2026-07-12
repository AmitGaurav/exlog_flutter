import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionRepositoryImpl({
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
      _firestore.collection('transactions');

  @override
  Future<List<Transaction>> getTransactions() async {
    final snapshot = await _col.where('userId', isEqualTo: _uid).get();

    final transactions =
        snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();

    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return transactions;
  }

  @override
  Future<String> createTransaction(Transaction transaction) async {
    final now = DateTime.now();
    final data = transaction
        .copyWith(userId: _uid, createdAt: now, updatedAt: now)
        .toFirestore();
    final docRef = await _col.add(data);
    return docRef.id;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction id must not be null');
    }
    final data = transaction.copyWith(updatedAt: DateTime.now()).toFirestore();
    await _col.doc(transaction.id).update(data);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _col.doc(transactionId).delete();
  }

  @override
  Future<Transaction?> findByTransactionReference(String reference) async {
    final snapshot = await _col
        .where('userId', isEqualTo: _uid)
        .where('transactionReference', isEqualTo: reference)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Transaction.fromFirestore(snapshot.docs.first);
  }

  String get _currentUsagePeriod {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  DocumentReference<Map<String, dynamic>> get _usageDoc =>
      _firestore.collection('users').doc(_uid).collection('usage').doc(_currentUsagePeriod);

  @override
  Future<int> getSmsImportUsageThisMonth() async {
    final snapshot = await _usageDoc.get();
    return (snapshot.data()?['smsImports'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> incrementSmsImportUsage() => _usageDoc.set({
        'smsImports': FieldValue.increment(1),
        'period': _currentUsagePeriod,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
