import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../transactions/domain/entities/transaction.dart';

final _amountFormat = NumberFormat('#,##,##0.00');

/// "Credit Transactions" list shown when Credits is expanded — individual
/// payee/date/amount/category rows for the currently selected period.
/// Sourced from the already-loaded TransactionBloc (no new Firestore read).
class CreditTransactionsList extends StatelessWidget {
  final List<Transaction> allTransactions;
  final DateTime periodStart;
  final DateTime periodEnd; // exclusive

  const CreditTransactionsList({
    super.key,
    required this.allTransactions,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  Widget build(BuildContext context) {
    final credits = allTransactions.where((t) {
      if (t.type != TransactionType.credit) return false;
      return !t.timestamp.isBefore(periodStart) && t.timestamp.isBefore(periodEnd);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (credits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No credits this period',
          style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 2),
          child: Text('Credit Transactions',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        for (final t in credits)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.payee, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(DateFormat('MMM d, yyyy').format(t.timestamp),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${_amountFormat.format(t.amount)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.income)),
                    Text(t.categoryName ?? 'Others', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
