import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/category.dart';

/// One category's contribution within a `PeriodSummary.byCategory` map entry.
/// Mirrors the Cloud Function's `byCategory[categoryId]` shape exactly:
/// `{ name, bucket, expense: {amount, count}, credit: {amount, count} }`.
class CategoryBreakdown extends Equatable {
  final String categoryId;
  final String name;
  final BucketType? bucket;
  final double expenseAmount;
  final int expenseCount;
  final double creditAmount;
  final int creditCount;

  const CategoryBreakdown({
    required this.categoryId,
    required this.name,
    this.bucket,
    this.expenseAmount = 0,
    this.expenseCount = 0,
    this.creditAmount = 0,
    this.creditCount = 0,
  });

  factory CategoryBreakdown.fromMap(String categoryId, Map<String, dynamic> data) {
    double amt(Map<String, dynamic>? m) => (m?['amount'] as num?)?.toDouble() ?? 0.0;
    int cnt(Map<String, dynamic>? m) => (m?['count'] as num?)?.toInt() ?? 0;

    final expense = data['expense'] as Map<String, dynamic>?;
    final credit = data['credit'] as Map<String, dynamic>?;
    final bucketRaw = data['bucket'] as String?;

    return CategoryBreakdown(
      categoryId: categoryId,
      name: data['name'] as String? ?? 'Uncategorized',
      bucket: bucketRaw == null ? null : BucketType.fromString(bucketRaw),
      expenseAmount: amt(expense),
      expenseCount: cnt(expense),
      creditAmount: amt(credit),
      creditCount: cnt(credit),
    );
  }

  CategoryBreakdown mergedWith(CategoryBreakdown other) => CategoryBreakdown(
        categoryId: categoryId,
        name: name,
        bucket: bucket ?? other.bucket,
        expenseAmount: expenseAmount + other.expenseAmount,
        expenseCount: expenseCount + other.expenseCount,
        creditAmount: creditAmount + other.creditAmount,
        creditCount: creditCount + other.creditCount,
      );

  @override
  List<Object?> get props =>
      [categoryId, name, bucket, expenseAmount, expenseCount, creditAmount, creditCount];
}
