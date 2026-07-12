import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/transaction_type_repository.dart';
import 'transaction_type_event.dart';
import 'transaction_type_state.dart';

class TransactionTypeBloc extends Bloc<TransactionTypeEvent, TransactionTypeState> {
  final TransactionTypeRepository _repository;

  TransactionTypeBloc(this._repository) : super(const TransactionTypeState()) {
    on<TransactionTypeLoadRequested>(_onLoad);
    on<TransactionTypeAddRequested>(_onAdd);
    on<TransactionTypeUpdateRequested>(_onUpdate);
    on<TransactionTypeDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(
    TransactionTypeLoadRequested event,
    Emitter<TransactionTypeState> emit,
  ) async {
    emit(state.copyWith(status: TransactionTypeStatus.loading, clearError: true));
    try {
      final types = await _repository.getTypes();
      emit(state.copyWith(status: TransactionTypeStatus.success, types: types));
    } catch (_) {
      emit(state.copyWith(status: TransactionTypeStatus.failure, error: 'Failed to load transaction types.'));
    }
  }

  Future<void> _onAdd(
    TransactionTypeAddRequested event,
    Emitter<TransactionTypeState> emit,
  ) async {
    try {
      final id = await _repository.createType(event.type);
      final saved = event.type.copyWith(id: id);
      final updated = List.of(state.types)..add(saved);
      updated.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(state.copyWith(status: TransactionTypeStatus.success, types: updated, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to create transaction type.'));
    }
  }

  Future<void> _onUpdate(
    TransactionTypeUpdateRequested event,
    Emitter<TransactionTypeState> emit,
  ) async {
    try {
      await _repository.updateType(event.type);
      final updated = state.types.map((t) => t.id == event.type.id ? event.type : t).toList();
      updated.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(state.copyWith(status: TransactionTypeStatus.success, types: updated, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update transaction type.'));
    }
  }

  Future<void> _onDelete(
    TransactionTypeDeleteRequested event,
    Emitter<TransactionTypeState> emit,
  ) async {
    try {
      await _repository.deleteType(event.typeId);
      final updated = state.types.where((t) => t.id != event.typeId).toList();
      emit(state.copyWith(status: TransactionTypeStatus.success, types: updated, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to delete transaction type.'));
    }
  }
}
