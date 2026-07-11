import 'package:equatable/equatable.dart';

/// Mirrors the server-side `PeriodSummary` document maintained by the
/// `aggregateTransaction` Cloud Function.
/// Reads from `users/{uid}/summaries_monthly/{YYYY-MM}` or
/// `users/{uid}/summaries_yearly/{YYYY}`.
class PeriodSummary extends Equatable {
  final String period;
  final double expenseAmount;
  final int expenseCount;
  final double creditAmount;
  final int creditCount;
  final double cashWithdrawalAmount;
  final double selfTransferAmount;
  final int totalCount;
  final Map<String, double> byCategory;
  final Map<String, double> customTypes;

  const PeriodSummary({
    required this.period,
    this.expenseAmount = 0,
    this.expenseCount = 0,
    this.creditAmount = 0,
    this.creditCount = 0,
    this.cashWithdrawalAmount = 0,
    this.selfTransferAmount = 0,
    this.totalCount = 0,
    this.byCategory = const {},
    this.customTypes = const {},
  });

  /// An empty summary (no transactions).
  static const empty = PeriodSummary(period: '');

  factory PeriodSummary.fromFirestore(
      String period, Map<String, dynamic> data) {
    final byType = (data['byType'] as Map<String, dynamic>?) ?? {};

    double getAmt(String key) =>
        ((byType[key] as Map<String, dynamic>?)?['amount'] as num?)
            ?.toDouble() ??
        0.0;
    int getCnt(String key) =>
        ((byType[key] as Map<String, dynamic>?)?['count'] as num?)?.toInt() ??
        0;

    final rawCategory = (data['byCategory'] as Map<String, dynamic>?) ?? {};
    final byCategory = rawCategory.map(
      (k, v) => MapEntry(
        k,
        ((v as Map<String, dynamic>?)?['amount'] as num?)?.toDouble() ?? 0.0,
      ),
    );

    final rawCustom = (data['customTypes'] as Map<String, dynamic>?) ?? {};
    final customTypes = rawCustom.map(
      (k, v) => MapEntry(
        k,
        ((v as Map<String, dynamic>?)?['amount'] as num?)?.toDouble() ?? 0.0,
      ),
    );

    return PeriodSummary(
      period: period,
      expenseAmount: getAmt('expense'),
      expenseCount: getCnt('expense'),
      creditAmount: getAmt('credit'),
      creditCount: getCnt('credit'),
      cashWithdrawalAmount: getAmt('cash_withdrawal'),
      selfTransferAmount: getAmt('self_transfer'),
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      byCategory: byCategory,
      customTypes: customTypes,
    );
  }

  @override
  List<Object?> get props => [
        period,
        expenseAmount,
        creditAmount,
        cashWithdrawalAmount,
        selfTransferAmount,
        totalCount,
      ];
}
