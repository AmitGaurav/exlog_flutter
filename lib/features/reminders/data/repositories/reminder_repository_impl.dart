import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReminderRepositoryImpl({
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
      _firestore.collection('recurringReminders');

  @override
  Future<List<Reminder>> getReminders() async {
    final snapshot = await _col.where('userId', isEqualTo: _uid).get();

    final reminders = snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
    reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return reminders;
  }

  @override
  Future<String> createReminder(Reminder reminder) async {
    final now = DateTime.now();
    final data = reminder
        .copyWith(userId: _uid, createdAt: now, updatedAt: now)
        .toFirestore();
    final docRef = await _col.add(data);
    return docRef.id;
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Reminder id must not be null');
    }
    final data = reminder.copyWith(updatedAt: DateTime.now()).toFirestore();
    await _col.doc(reminder.id).update(data);
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    await _col.doc(reminderId).delete();
  }
}
