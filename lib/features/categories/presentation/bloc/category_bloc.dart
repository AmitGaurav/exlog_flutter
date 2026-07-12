import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/category_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _repository;

  CategoryBloc(this._repository) : super(const CategoryState()) {
    on<CategoryLoadRequested>(_onLoad);
    on<CategoryAddRequested>(_onAdd);
    on<CategoryUpdateRequested>(_onUpdate);
    on<CategoryDeleteRequested>(_onDelete);
    on<CategoryErrorCleared>(_onErrorCleared);
  }

  Future<void> _onLoad(
    CategoryLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading, clearError: true));
    try {
      final categories = await _repository.getCategories();
      emit(state.copyWith(status: CategoryStatus.success, categories: categories));
    } catch (_) {
      emit(state.copyWith(
        status: CategoryStatus.failure,
        error: 'Failed to load categories.',
      ));
    }
  }

  Future<void> _onAdd(
    CategoryAddRequested event,
    Emitter<CategoryState> emit,
  ) async {
    final isDuplicate = state.categories.any(
      (c) =>
          c.name.toLowerCase() == event.category.name.toLowerCase() &&
          c.bucket == event.category.bucket,
    );
    if (isDuplicate) {
      emit(state.copyWith(
        error:
            '"${event.category.name}" already exists in ${event.category.bucket.displayName}.',
      ));
      return;
    }
    try {
      final id = await _repository.createCategory(event.category);
      final saved = event.category.copyWith(id: id);
      final updated = List.of(state.categories)..add(saved);
      _sortCategories(updated);
      emit(state.copyWith(
        status: CategoryStatus.success,
        categories: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to add category.'));
    }
  }

  Future<void> _onUpdate(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.updateCategory(event.category);
      final updated = state.categories
          .map((c) => c.id == event.category.id ? event.category : c)
          .toList();
      _sortCategories(updated);
      emit(state.copyWith(
        status: CategoryStatus.success,
        categories: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update category.'));
    }
  }

  Future<void> _onDelete(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _repository.deleteCategory(event.categoryId);
      final updated =
          state.categories.where((c) => c.id != event.categoryId).toList();
      emit(state.copyWith(
        status: CategoryStatus.success,
        categories: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to delete category.'));
    }
  }

  void _onErrorCleared(
    CategoryErrorCleared event,
    Emitter<CategoryState> emit,
  ) =>
      emit(state.copyWith(clearError: true));

  void _sortCategories(List list) {
    list.sort((a, b) {
      final cmp = a.bucket.sortOrder.compareTo(b.bucket.sortOrder);
      return cmp != 0 ? cmp : a.name.compareTo(b.name);
    });
  }
}
