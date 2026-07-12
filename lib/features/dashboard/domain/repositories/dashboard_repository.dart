import '../entities/period_summary.dart';

abstract interface class DashboardRepository {
  /// Fetch summary for a given month (YYYY-MM format → `summaries_monthly`).
  Future<PeriodSummary> getMonthSummary({required String period});

  /// Fetch summary for a given year (YYYY format → `summaries_yearly`).
  Future<PeriodSummary> getYearSummary({required String year});

  /// Batched fetch (parallel) for the Analytics tab. Returns exactly one
  /// entry per requested period, in the same order — missing docs come
  /// back as `PeriodSummary.empty` (with `period` set) since the "Monthly
  /// Expenses & Income" section always shows all 12 fixed month slots.
  Future<List<PeriodSummary>> getMonthSummaries(List<String> periods);

  /// Batched fetch (parallel) for the Analytics tab. Missing docs are
  /// dropped — the Year-on-Year ranked list and all-time rollups only
  /// need years that actually have data.
  Future<List<PeriodSummary>> getYearSummaries(List<String> years);
}
