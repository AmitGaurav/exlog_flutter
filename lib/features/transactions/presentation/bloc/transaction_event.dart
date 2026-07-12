import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionLoadRequested extends TransactionEvent {
  const TransactionLoadRequested();
}

class TransactionAddRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionAddRequested(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionUpdateRequested extends TransactionEvent {
  final Transaction transaction;

  const TransactionUpdateRequested(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class TransactionDeleteRequested extends TransactionEvent {
  final String transactionId;

  const TransactionDeleteRequested(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class TransactionFilterChanged extends TransactionEvent {
  final TransactionFilter filter;

  const TransactionFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class TransactionSearchChanged extends TransactionEvent {
  final String searchText;

  const TransactionSearchChanged(this.searchText);

  @override
  List<Object?> get props => [searchText];
}

class TransactionFiltersCleared extends TransactionEvent {
  const TransactionFiltersCleared();
}

class TransactionErrorCleared extends TransactionEvent {
  const TransactionErrorCleared();
}
