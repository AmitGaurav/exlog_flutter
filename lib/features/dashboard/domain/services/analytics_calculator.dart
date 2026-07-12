import '../entities/category_breakdown.dart';
import '../entities/period_summary.dart';

/// One row in the "Monthly Expenses & Income" list.
class MonthRow {
  final String period; // "YYYY-MM"
  final String label; // "Jun '26"
  final bool isCurrent;
  final double expenseAmount;
  final int expenseCount;
  final double creditAmount;
  final int creditCount;
  final double barFraction; // 0..1, relative to the max month's expense

  const MonthRow({
    required this.period,
    required this.label,
    required this.isCurrent,
    required this.expenseAmount,
    required this.expenseCount,
    required this.creditAmount,
    required this.creditCount,
    required this.barFraction,
  });

  double get net => creditAmount - expenseAmount;
}

class MonthStat {
  final double amount;
  final String label; // "Jun"
  const MonthStat({required this.amount, required this.label});
}

class MonthlyOverview {
  final double totalExpense;
  final int txnCount;
  final double monthlyAvg;
  final MonthStat? highest;
  final MonthStat? lowest;
  final List<MonthRow> rows; // most recent first

  const MonthlyOverview({
    required this.totalExpense,
    required this.txnCount,
    required this.monthlyAvg,
    required this.highest,
    required this.lowest,
    required this.rows,
  });

  /// Spent/Earned/Net footer for the Monthly Expenses & Income section.
  double get totalSpent => rows.fold(0.0, (sum, r) => sum + r.expenseAmount);
  double get totalEarned => rows.fold(0.0, (sum, r) => sum + r.creditAmount);
  double get totalNet => totalEarned - totalSpent;
}

class CurrentVsLastMonth {
  final double percentChange;
  final bool isIncrease;
  final double thisAmount;
  final double lastAmount;

  const CurrentVsLastMonth({
    required this.percentChange,
    required this.isIncrease,
    required this.thisAmount,
    required this.lastAmount,
  });
}

class YearRow {
  final String year;
  final double amount;
  final int count;
  final double barFraction;

  const YearRow({
    required this.year,
    required this.amount,
    required this.count,
    required this.barFraction,
  });
}

class YearOnYearResult {
  final List<YearRow> rows; // sorted descending by amount
  final double total;
  final int totalTxns;
  final int yearsOfData;

  const YearOnYearResult({
    required this.rows,
    required this.total,
    required this.totalTxns,
    required this.yearsOfData,
  });
}

class TopCategoriesResult {
  final List<CategoryBreakdown> spendingCurrentYear;
  final List<CategoryBreakdown> spendingAllTime;
  final List<CategoryBreakdown> creditsCurrentYear;
  final List<CategoryBreakdown> creditsAllTime;

  const TopCategoriesResult({
    required this.spendingCurrentYear,
    required this.spendingAllTime,
    required this.creditsCurrentYear,
    required this.creditsAllTime,
  });
}

class QuickStats {
  final int totalExpenseTxns;
  final int totalCreditTxns;
  final double avgPerTxn;
  final double projectedYearly;
  final String? topCategoryName;
  final double monthlyAvg;

  const QuickStats({
    required this.totalExpenseTxns,
    required this.totalCreditTxns,
    required this.avgPerTxn,
    required this.projectedYearly,
    required this.topCategoryName,
    required this.monthlyAvg,
  });
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Pure aggregation functions over already-fetched [PeriodSummary] lists —
/// no I/O. Mirrors iOS's `DashboardViewModel` computed properties so the
/// Analytics tab's numbers match 1:1.
class AnalyticsCalculator {
  const AnalyticsCalculator._();

  /// [monthlySummaries] must be exactly 12 entries, chronological
  /// (oldest first, current month last) — the shape `getMonthSummaries`
  /// returns when called with `last12MonthPeriods()`.
  static MonthlyOverview monthlyOverview(List<PeriodSummary> monthlySummaries, DateTime now) {
    final maxExpense = monthlySummaries.fold<double>(
      0, (max, s) => s.expenseAmount > max ? s.expenseAmount : max);

    final currentPeriod = _periodKey(now.year, now.month);

    final rows = monthlySummaries.map((s) {
      final parts = s.period.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return MonthRow(
        period: s.period,
        label: "${_monthNames[month - 1]} '${(year % 100).toString().padLeft(2, '0')}",
        isCurrent: s.period == currentPeriod,
        expenseAmount: s.expenseAmount,
        expenseCount: s.expenseCount,
        creditAmount: s.creditAmount,
        creditCount: s.creditCount,
        barFraction: maxExpense > 0 ? s.expenseAmount / maxExpense : 0,
      );
    }).toList();

    final nonZero = monthlySummaries.where((s) => s.expenseAmount > 0).toList();
    MonthStat? statFor(PeriodSummary Function(List<PeriodSummary>) pick) {
      if (nonZero.isEmpty) return null;
      final s = pick(nonZero);
      final month = int.parse(s.period.split('-')[1]);
      return MonthStat(amount: s.expenseAmount, label: _monthNames[month - 1]);
    }

    final highest = statFor((l) => l.reduce((a, b) => a.expenseAmount >= b.expenseAmount ? a : b));
    final lowest = statFor((l) => l.reduce((a, b) => a.expenseAmount <= b.expenseAmount ? a : b));

    final totalExpense = monthlySummaries.fold(0.0, (sum, s) => sum + s.expenseAmount);
    final txnCount = monthlySummaries.fold(0, (sum, s) => sum + s.totalCount);

    return MonthlyOverview(
      totalExpense: totalExpense,
      txnCount: txnCount,
      monthlyAvg: monthlySummaries.isEmpty ? 0 : totalExpense / monthlySummaries.length,
      highest: highest,
      lowest: lowest,
      rows: rows.reversed.toList(),
    );
  }

  /// [monthlySummaries] chronological, current month last (same shape as above).
  static CurrentVsLastMonth currentVsLastMonth(List<PeriodSummary> monthlySummaries) {
    if (monthlySummaries.length < 2) {
      return const CurrentVsLastMonth(percentChange: 0, isIncrease: false, thisAmount: 0, lastAmount: 0);
    }
    final current = monthlySummaries.last.expenseAmount;
    final last = monthlySummaries[monthlySummaries.length - 2].expenseAmount;
    final diff = current - last;
    final percent = last > 0 ? (diff / last) * 100 : 0.0;
    return CurrentVsLastMonth(
      percentChange: percent,
      isIncrease: diff >= 0,
      thisAmount: current,
      lastAmount: last,
    );
  }

  /// [yearlySummaries] may be in any order and should already exclude
  /// empty/missing years (see `DashboardRepository.getYearSummaries`).
  static YearOnYearResult yearOnYear(List<PeriodSummary> yearlySummaries) {
    final withActivity = yearlySummaries.where((s) => s.expenseAmount > 0 || s.totalCount > 0).toList()
      ..sort((a, b) => b.expenseAmount.compareTo(a.expenseAmount));

    final maxAmount = withActivity.isEmpty ? 0.0 : withActivity.first.expenseAmount;

    final rows = withActivity
        .map((s) => YearRow(
              year: s.period,
              amount: s.expenseAmount,
              count: s.totalCount,
              barFraction: maxAmount > 0 ? s.expenseAmount / maxAmount : 0,
            ))
        .toList();

    return YearOnYearResult(
      rows: rows,
      total: withActivity.fold(0.0, (sum, s) => sum + s.expenseAmount),
      totalTxns: withActivity.fold(0, (sum, s) => sum + s.totalCount),
      yearsOfData: withActivity.length,
    );
  }

  static TopCategoriesResult topCategories(
    List<PeriodSummary> yearlySummaries,
    PeriodSummary? currentYearSummary,
  ) {
    List<CategoryBreakdown> topExpense(Iterable<CategoryBreakdown> entries) {
      final list = entries.where((c) => c.expenseAmount > 0).toList()
        ..sort((a, b) => b.expenseAmount.compareTo(a.expenseAmount));
      return list.take(5).toList();
    }

    List<CategoryBreakdown> topCredit(Iterable<CategoryBreakdown> entries) {
      final list = entries.where((c) => c.creditAmount > 0).toList()
        ..sort((a, b) => b.creditAmount.compareTo(a.creditAmount));
      return list.take(5).toList();
    }

    final currentYearCategories = currentYearSummary?.byCategory.values ?? const <CategoryBreakdown>[];

    final allTimeMerged = <String, CategoryBreakdown>{};
    for (final year in yearlySummaries) {
      for (final entry in year.byCategory.entries) {
        allTimeMerged.update(
          entry.key,
          (existing) => existing.mergedWith(entry.value),
          ifAbsent: () => entry.value,
        );
      }
    }

    return TopCategoriesResult(
      spendingCurrentYear: topExpense(currentYearCategories),
      spendingAllTime: topExpense(allTimeMerged.values),
      creditsCurrentYear: topCredit(currentYearCategories),
      creditsAllTime: topCredit(allTimeMerged.values),
    );
  }

  static QuickStats quickStats({
    required List<PeriodSummary> yearlySummaries,
    required PeriodSummary? currentYearSummary,
    required double monthlyAvg,
    required List<CategoryBreakdown> allTimeSpendingCategories,
    required DateTime now,
  }) {
    final totalExpenseTxns = yearlySummaries.fold(0, (sum, s) => sum + s.expenseCount);
    final totalCreditTxns = yearlySummaries.fold(0, (sum, s) => sum + s.creditCount);
    final totalExpenseAmount = yearlySummaries.fold(0.0, (sum, s) => sum + s.expenseAmount);

    final currentYearExpense = currentYearSummary?.expenseAmount ?? 0;
    final projectedYearly = now.month > 0 ? (currentYearExpense / now.month) * 12 : 0.0;

    return QuickStats(
      totalExpenseTxns: totalExpenseTxns,
      totalCreditTxns: totalCreditTxns,
      avgPerTxn: totalExpenseTxns > 0 ? totalExpenseAmount / totalExpenseTxns : 0,
      projectedYearly: projectedYearly,
      topCategoryName: allTimeSpendingCategories.isEmpty ? null : allTimeSpendingCategories.first.name,
      monthlyAvg: monthlyAvg,
    );
  }

  static List<String> last12MonthPeriods(DateTime now) {
    return List.generate(12, (i) {
      final offset = 11 - i;
      final date = DateTime(now.year, now.month - offset);
      return _periodKey(date.year, date.month);
    });
  }

  static List<String> lastNYears(DateTime now, int n) {
    return List.generate(n, (i) => (now.year - i).toString());
  }

  static String _periodKey(int year, int month) => '$year-${month.toString().padLeft(2, '0')}';
}
