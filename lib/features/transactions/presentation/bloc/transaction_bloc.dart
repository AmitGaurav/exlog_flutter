import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repository;

  TransactionBloc(this._repository) : super(const TransactionState()) {
    on<TransactionLoadRequested>(_onLoad);
    on<TransactionAddRequested>(_onAdd);
    on<TransactionUpdateRequested>(_onUpdate);
    on<TransactionDeleteRequested>(_onDelete);
    on<TransactionFilterChanged>(_onFilterChanged);
    on<TransactionSearchChanged>(_onSearchChanged);
    on<TransactionFiltersCleared>(_onFiltersCleared);
    on<TransactionErrorCleared>(_onErrorCleared);
  }

  Future<void> _onLoad(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(status: TransactionStatus.loading, clearError: true));
    try {
      final transactions = await _repository.getTransactions();
      emit(state.copyWith(status: TransactionStatus.success, transactions: transactions));
    } catch (_) {
      emit(state.copyWith(
        status: TransactionStatus.failure,
        error: 'Failed to load transactions.',
      ));
    }
  }

  Future<void> _onAdd(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final id = await _repository.createTransaction(event.transaction);
      final saved = event.transaction.copyWith(id: id);
      final updated = List.of(state.transactions)..add(saved);
      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to add transaction.'));
    }
  }

  Future<void> _onUpdate(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.updateTransaction(event.transaction);
      final updated = state.transactions
          .map((t) => t.id == event.transaction.id ? event.transaction : t)
          .toList();
      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update transaction.'));
    }
  }

  Future<void> _onDelete(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _repository.deleteTransaction(event.transactionId);
      final updated =
          state.transactions.where((t) => t.id != event.transactionId).toList();
      emit(state.copyWith(
        status: TransactionStatus.success,
        transactions: updated,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to delete transaction.'));
    }
  }

  void _onFilterChanged(
    TransactionFilterChanged event,
    Emitter<TransactionState> emit,
  ) =>
      emit(state.copyWith(filter: event.filter));

  void _onSearchChanged(
    TransactionSearchChanged event,
    Emitter<TransactionState> emit,
  ) =>
      emit(state.copyWith(filter: state.filter.copyWith(searchText: event.searchText)));

  void _onFiltersCleared(
    TransactionFiltersCleared event,
    Emitter<TransactionState> emit,
  ) =>
      emit(state.copyWith(filter: const TransactionFilter()));

  void _onErrorCleared(
    TransactionErrorCleared event,
    Emitter<TransactionState> emit,
  ) =>
      emit(state.copyWith(clearError: true));
}
