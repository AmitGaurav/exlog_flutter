import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class CategoryLoadRequested extends CategoryEvent {
  const CategoryLoadRequested();
}

class CategoryAddRequested extends CategoryEvent {
  final Category category;

  const CategoryAddRequested(this.category);

  @override
  List<Object?> get props => [category];
}

class CategoryUpdateRequested extends CategoryEvent {
  final Category category;

  const CategoryUpdateRequested(this.category);

  @override
  List<Object?> get props => [category];
}

class CategoryDeleteRequested extends CategoryEvent {
  final String categoryId;

  const CategoryDeleteRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class CategoryErrorCleared extends CategoryEvent {
  const CategoryErrorCleared();
}
