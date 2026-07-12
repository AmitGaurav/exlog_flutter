import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/user_profile_repository.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserProfileRepository _repository;

  UserProfileBloc(this._repository) : super(const UserProfileState()) {
    on<UserProfileLoadRequested>(_onLoad);
    on<UserProfileCurrencyChanged>(_onCurrencyChanged);
    on<UserProfileAIParserConfigChanged>(_onAIParserConfigChanged);
    on<UserProfileSelfNamesChanged>(_onSelfNamesChanged);
  }

  Future<void> _onLoad(
    UserProfileLoadRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(status: UserProfileStatus.loading, clearError: true));
    try {
      final profile = await _repository.getProfile();
      emit(state.copyWith(status: UserProfileStatus.success, profile: profile));
    } catch (_) {
      emit(state.copyWith(status: UserProfileStatus.failure, error: 'Failed to load profile.'));
    }
  }

  Future<void> _onCurrencyChanged(
    UserProfileCurrencyChanged event,
    Emitter<UserProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null) return;
    try {
      await _repository.updatePreferredCurrency(event.currencyCode);
      emit(state.copyWith(profile: current.copyWith(preferredCurrency: event.currencyCode)));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update currency.'));
    }
  }

  Future<void> _onAIParserConfigChanged(
    UserProfileAIParserConfigChanged event,
    Emitter<UserProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null) return;
    try {
      await _repository.updateAIParserConfig(event.config);
      emit(state.copyWith(profile: current.copyWith(aiParserConfig: event.config)));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update AI parser settings.'));
    }
  }

  Future<void> _onSelfNamesChanged(
    UserProfileSelfNamesChanged event,
    Emitter<UserProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null) return;
    try {
      await _repository.updateSelfNames(event.selfNames);
      emit(state.copyWith(profile: current.copyWith(selfNames: event.selfNames)));
    } catch (_) {
      emit(state.copyWith(error: 'Failed to update self-transfer names.'));
    }
  }
}
