import 'package:equatable/equatable.dart';
import '../../domain/entities/period_summary.dart';
import 'dashboard_event.dart';

class DashboardState extends Equatable {
  final DashboardTab selectedTab;
  final PeriodSummary? summary;
  final bool isLoading;
  final String? error;

  /// Analytics tab data — fetched once, lazily, the first time the tab is
  /// opened (see [analyticsLoaded]), then cached for the rest of the session.
  final List<PeriodSummary> monthlySummaries; // trailing 12 months, oldest first
  final List<PeriodSummary> yearlySummaries; // non-empty years only
  final bool isAnalyticsLoading;
  final bool analyticsLoaded;
  final String? analyticsError;

  const DashboardState({
    this.selectedTab = DashboardTab.thisMonth,
    this.summary,
    this.isLoading = false,
    this.error,
    this.monthlySummaries = const [],
    this.yearlySummaries = const [],
    this.isAnalyticsLoading = false,
    this.analyticsLoaded = false,
    this.analyticsError,
  });

  DashboardState copyWith({
    DashboardTab? selectedTab,
    PeriodSummary? summary,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<PeriodSummary>? monthlySummaries,
    List<PeriodSummary>? yearlySummaries,
    bool? isAnalyticsLoading,
    bool? analyticsLoaded,
    String? analyticsError,
    bool clearAnalyticsError = false,
  }) {
    return DashboardState(
      selectedTab: selectedTab ?? this.selectedTab,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      monthlySummaries: monthlySummaries ?? this.monthlySummaries,
      yearlySummaries: yearlySummaries ?? this.yearlySummaries,
      isAnalyticsLoading: isAnalyticsLoading ?? this.isAnalyticsLoading,
      analyticsLoaded: analyticsLoaded ?? this.analyticsLoaded,
      analyticsError: clearAnalyticsError ? null : (analyticsError ?? this.analyticsError),
    );
  }

  @override
  List<Object?> get props => [
        selectedTab,
        summary,
        isLoading,
        error,
        monthlySummaries,
        yearlySummaries,
        isAnalyticsLoading,
        analyticsLoaded,
        analyticsError,
      ];
}
