import 'package:equatable/equatable.dart';
import '../../domain/entities/period_summary.dart';
import 'dashboard_event.dart';

class DashboardState extends Equatable {
  final DashboardTab selectedTab;
  final PeriodSummary? summary;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.selectedTab = DashboardTab.thisMonth,
    this.summary,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardTab? selectedTab,
    PeriodSummary? summary,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      selectedTab: selectedTab ?? this.selectedTab,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [selectedTab, summary, isLoading, error];
}
