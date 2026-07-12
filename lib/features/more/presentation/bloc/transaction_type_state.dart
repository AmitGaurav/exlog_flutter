import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_type_model.dart';

enum TransactionTypeStatus { initial, loading, success, failure }

class TransactionTypeState extends Equatable {
  final TransactionTypeStatus status;
  final List<TransactionTypeModel> types;
  final String? error;

  const TransactionTypeState({
    this.status = TransactionTypeStatus.initial,
    this.types = const [],
    this.error,
  });

  TransactionTypeState copyWith({
    TransactionTypeStatus? status,
    List<TransactionTypeModel>? types,
    String? error,
    bool clearError = false,
  }) =>
      TransactionTypeState(
        status: status ?? this.status,
        types: types ?? this.types,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, types, error];
}
