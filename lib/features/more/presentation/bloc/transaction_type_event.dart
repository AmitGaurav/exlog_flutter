import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_type_model.dart';

abstract class TransactionTypeEvent extends Equatable {
  const TransactionTypeEvent();

  @override
  List<Object?> get props => [];
}

class TransactionTypeLoadRequested extends TransactionTypeEvent {
  const TransactionTypeLoadRequested();
}

class TransactionTypeAddRequested extends TransactionTypeEvent {
  final TransactionTypeModel type;
  const TransactionTypeAddRequested(this.type);

  @override
  List<Object?> get props => [type];
}

class TransactionTypeUpdateRequested extends TransactionTypeEvent {
  final TransactionTypeModel type;
  const TransactionTypeUpdateRequested(this.type);

  @override
  List<Object?> get props => [type];
}

class TransactionTypeDeleteRequested extends TransactionTypeEvent {
  final String typeId;
  const TransactionTypeDeleteRequested(this.typeId);

  @override
  List<Object?> get props => [typeId];
}
