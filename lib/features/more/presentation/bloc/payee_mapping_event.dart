import 'package:equatable/equatable.dart';

import '../../domain/entities/payee_mapping.dart';

abstract class PayeeMappingEvent extends Equatable {
  const PayeeMappingEvent();

  @override
  List<Object?> get props => [];
}

class PayeeMappingLoadRequested extends PayeeMappingEvent {
  const PayeeMappingLoadRequested();
}

class PayeeMappingAddRequested extends PayeeMappingEvent {
  final PayeeMapping mapping;
  const PayeeMappingAddRequested(this.mapping);

  @override
  List<Object?> get props => [mapping];
}

class PayeeMappingDeleteRequested extends PayeeMappingEvent {
  final String mappingId;
  const PayeeMappingDeleteRequested(this.mappingId);

  @override
  List<Object?> get props => [mappingId];
}

class PayeeMappingSearchChanged extends PayeeMappingEvent {
  final String query;
  const PayeeMappingSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PayeeMappingErrorCleared extends PayeeMappingEvent {
  const PayeeMappingErrorCleared();
}
