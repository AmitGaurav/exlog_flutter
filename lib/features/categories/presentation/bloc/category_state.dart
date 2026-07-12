import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

enum CategoryStatus { initial, loading, success, failure }

class CategoryState extends Equatable {
  final CategoryStatus status;
  final List<Category> categories;
  final String? error;

  const CategoryState({
    this.status = CategoryStatus.initial,
    this.categories = const [],
    this.error,
  });

  Map<BucketType, List<Category>> get categoriesByBucket {
    final map = <BucketType, List<Category>>{};
    for (final cat in categories) {
      (map[cat.bucket] ??= []).add(cat);
    }
    return map;
  }

  CategoryState copyWith({
    CategoryStatus? status,
    List<Category>? categories,
    String? error,
    bool clearError = false,
  }) =>
      CategoryState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, categories, error];
}
