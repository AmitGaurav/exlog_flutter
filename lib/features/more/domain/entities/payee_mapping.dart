import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PayeeMapping extends Equatable {
  final String? id;
  final String payeeName;
  final String normalizedPayeeName;
  final String categoryId;
  final String? categoryName;
  final String userId;
  final int matchCount;
  final DateTime? lastUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayeeMapping({
    this.id,
    required this.payeeName,
    required this.normalizedPayeeName,
    required this.categoryId,
    this.categoryName,
    required this.userId,
    this.matchCount = 0,
    this.lastUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayeeMapping.create({
    required String payeeName,
    required String categoryId,
    String? categoryName,
    required String userId,
  }) {
    final now = DateTime.now();
    return PayeeMapping(
      payeeName: payeeName,
      normalizedPayeeName: payeeName.toLowerCase().trim(),
      categoryId: categoryId,
      categoryName: categoryName,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PayeeMapping.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PayeeMapping(
      id: doc.id,
      payeeName: data['payeeName'] as String? ?? '',
      normalizedPayeeName: data['normalizedPayeeName'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String?,
      userId: data['userId'] as String? ?? '',
      matchCount: data['matchCount'] as int? ?? 0,
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'payeeName': payeeName,
        'normalizedPayeeName': normalizedPayeeName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'userId': userId,
        'matchCount': matchCount,
        'lastUsed': lastUsed == null ? null : Timestamp.fromDate(lastUsed!),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Ported from iOS PayeeMapping.matches(_:threshold:): exact → substring
  /// (either direction) → Levenshtein-distance fuzzy match.
  bool matches(String otherPayeeName, {double threshold = 0.8}) {
    final normalized = otherPayeeName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final stored = normalizedPayeeName.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (stored == normalized) return true;
    if (stored.contains(normalized)) return true;
    if (normalized.contains(stored)) return true;

    return _levenshteinSimilarity(stored, normalized) >= threshold;
  }

  double _levenshteinSimilarity(String s1, String s2) {
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    return maxLength > 0 ? 1.0 - distance / maxLength : 1.0;
  }

  int _levenshteinDistance(String s1, String s2) {
    final rows = s1.length + 1;
    final cols = s2.length + 1;
    final distance = List.generate(rows, (i) => List.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      distance[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      distance[0][j] = j;
    }
    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        distance[i][j] = [
          distance[i - 1][j] + 1,
          distance[i][j - 1] + 1,
          distance[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return distance[s1.length][s2.length];
  }

  PayeeMapping recordMatch() => copyWith(
        matchCount: matchCount + 1,
        lastUsed: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  PayeeMapping copyWith({
    String? id,
    String? payeeName,
    String? categoryId,
    String? categoryName,
    int? matchCount,
    DateTime? lastUsed,
    DateTime? updatedAt,
  }) =>
      PayeeMapping(
        id: id ?? this.id,
        payeeName: payeeName ?? this.payeeName,
        normalizedPayeeName: payeeName != null ? payeeName.toLowerCase().trim() : normalizedPayeeName,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        userId: userId,
        matchCount: matchCount ?? this.matchCount,
        lastUsed: lastUsed ?? this.lastUsed,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        payeeName,
        normalizedPayeeName,
        categoryId,
        categoryName,
        userId,
        matchCount,
        lastUsed,
        createdAt,
        updatedAt,
      ];
}
