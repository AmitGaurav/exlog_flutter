import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/services/analytics_calculator.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardTabChanged>(_onTabChanged);
    on<DashboardAnalyticsLoadRequested>(_onAnalyticsLoad);
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
      emit(state.copyWith(selectedTab: event.tab));
      if (!state.analyticsLoaded) {
        add(const DashboardAnalyticsLoadRequested());
      }
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

  Future<void> _onAnalyticsLoad(
    DashboardAnalyticsLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isAnalyticsLoading: true, clearAnalyticsError: true));
    try {
      final now = DateTime.now();
      final months = await _repository.getMonthSummaries(AnalyticsCalculator.last12MonthPeriods(now));
      final years = await _repository.getYearSummaries(AnalyticsCalculator.lastNYears(now, 10));
      emit(state.copyWith(
        monthlySummaries: months,
        yearlySummaries: years,
        isAnalyticsLoading: false,
        analyticsLoaded: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isAnalyticsLoading: false,
        analyticsError: 'Failed to load analytics.',
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
