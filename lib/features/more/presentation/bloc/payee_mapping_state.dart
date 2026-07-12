import 'package:equatable/equatable.dart';

import '../../domain/entities/payee_mapping.dart';

enum PayeeMappingStatus { initial, loading, success, failure }

class PayeeMappingState extends Equatable {
  final PayeeMappingStatus status;
  final List<PayeeMapping> mappings;
  final String searchQuery;
  final String? error;

  const PayeeMappingState({
    this.status = PayeeMappingStatus.initial,
    this.mappings = const [],
    this.searchQuery = '',
    this.error,
  });

  List<PayeeMapping> get filteredMappings {
    if (searchQuery.isEmpty) return mappings;
    final q = searchQuery.toLowerCase();
    return mappings.where((m) => m.payeeName.toLowerCase().contains(q)).toList();
  }

  PayeeMappingState copyWith({
    PayeeMappingStatus? status,
    List<PayeeMapping>? mappings,
    String? searchQuery,
    String? error,
    bool clearError = false,
  }) =>
      PayeeMappingState(
        status: status ?? this.status,
        mappings: mappings ?? this.mappings,
        searchQuery: searchQuery ?? this.searchQuery,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, mappings, searchQuery, error];
}
