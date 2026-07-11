import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardTabChanged>(_onTabChanged);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final summary = await _fetchForTab(state.selectedTab);
      emit(state.copyWith(summary: summary, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load summary. Pull to refresh.',
      ));
    }
  }

  Future<void> _onTabChanged(
    DashboardTabChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.tab == DashboardTab.analytics) {
      // Analytics tab — no summary needed yet
      emit(state.copyWith(selectedTab: event.tab));
      return;
    }
    emit(state.copyWith(selectedTab: event.tab, isLoading: true, clearError: true));
    try {
      final summary = await _fetchForTab(event.tab);
      emit(state.copyWith(summary: summary, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load summary.',
      ));
    }
  }

  Future<dynamic> _fetchForTab(DashboardTab tab) {
    final now = DateTime.now();
    if (tab == DashboardTab.thisMonth) {
      final period = DateFormat('yyyy-MM').format(now);
      return _repository.getMonthSummary(period: period);
    } else {
      final year = now.year.toString();
      return _repository.getYearSummary(year: year);
    }
  }
}
