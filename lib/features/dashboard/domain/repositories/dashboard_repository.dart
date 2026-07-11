import '../entities/period_summary.dart';

abstract interface class DashboardRepository {
  /// Fetch summary for a given month (YYYY-MM format → `summaries_monthly`).
  Future<PeriodSummary> getMonthSummary({required String period});

  /// Fetch summary for a given year (YYYY format → `summaries_yearly`).
  Future<PeriodSummary> getYearSummary({required String year});
}
