import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CategoryRepositoryImpl({
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
      _firestore.collection('categories');

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _col
        .where('userId', isEqualTo: _uid)
        .where('isActive', isEqualTo: true)
        .get();

    final categories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();

    categories.sort((a, b) {
      final bucketCmp = a.bucket.sortOrder.compareTo(b.bucket.sortOrder);
      return bucketCmp != 0 ? bucketCmp : a.name.compareTo(b.name);
    });

    return categories;
  }

  @override
  Future<String> createCategory(Category category) async {
    final now = DateTime.now();
    final data = category
        .copyWith(userId: _uid, createdAt: now, updatedAt: now)
        .toFirestore();
    final docRef = await _col.add(data);
    return docRef.id;
  }

  @override
  Future<void> updateCategory(Category category) async {
    if (category.id == null) throw ArgumentError('Category id must not be null');
    final data = category.copyWith(updatedAt: DateTime.now()).toFirestore();
    await _col.doc(category.id).update(data);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _col.doc(categoryId).delete();
  }
}
