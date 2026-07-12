import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/payee_mapping_repository.dart';
import 'payee_mapping_event.dart';
import 'payee_mapping_state.dart';

class PayeeMappingBloc extends Bloc<PayeeMappingEvent, PayeeMappingState> {
  final PayeeMappingRepository _repository;

  PayeeMappingBloc(this._repository) : super(const PayeeMappingState()) {
    on<PayeeMappingLoadRequested>(_onLoad);
    on<PayeeMappingAddRequested>(_onAdd);
    on<PayeeMappingDeleteRequested>(_onDelete);
    on<PayeeMappingSearchChanged>(_onSearchChanged);
    on<PayeeMappingErrorCleared>((event, emit) => emit(state.copyWith(clearError: true)));
  }

  Future<void> _onLoad(
    PayeeMappingLoadRequested event,
    Emitter<PayeeMappingState> emit,
  ) async {
    emit(state.copyWith(status: PayeeMappingStatus.loading, clearError: true));
    try {
      final mappings = await _repository.getMappings();
      emit(state.copyWith(status: PayeeMappingStatus.success, mappings: mappings));
    } catch (_) {
      emit(state.copyWith(status: PayeeMappingStatus.failure, error: 'Failed to load payee mappings.'));
    }
  }

  Future<void> _onAdd(
    PayeeMappingAddRequested event,
    Emitter<PayeeMappingState> emit,
  ) async {
    final duplicate = state.mappings.any((m) =>
        m.normalizedPayeeName == event.mapping.normalizedPayeeName &&
        m.categoryId == event.mapping.categoryId);
    if (duplicate) {
      emit(state.copyWith(error: 'A mapping for this payee and category already exists.'));
      return;
    }
    try {
      final id = await _repository.createMapping(event.mapping);
      final saved = event.mapping.copyWith(id: id);
      final updated = List.of(state.mappings)..add(saved);
      emit(state.copyWith(status: PayeeMappingStatus.success, mappings: updated, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to create payee mapping.'));
    }
  }

  Future<void> _onDelete(
    PayeeMappingDeleteRequested event,
    Emitter<PayeeMappingState> emit,
  ) async {
    try {
      await _repository.deleteMapping(event.mappingId);
      final updated = state.mappings.where((m) => m.id != event.mappingId).toList();
      emit(state.copyWith(status: PayeeMappingStatus.success, mappings: updated, clearError: true));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to delete payee mapping.'));
    }
  }

  void _onSearchChanged(PayeeMappingSearchChanged event, Emitter<PayeeMappingState> emit) =>
      emit(state.copyWith(searchQuery: event.query));
}
