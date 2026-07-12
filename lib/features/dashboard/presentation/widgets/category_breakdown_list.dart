import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/category_breakdown.dart';

final _amountFormat = NumberFormat('#,##,##0.00');

enum CategoryBreakdownKind { expense, credit }

/// "Category Breakdown" list shown when Total Expenses / Credits is
/// expanded on the This Month / This Year tabs — category name, bucket
/// type, txn count, amount, and a blue proportion bar vs the top entry.
class CategoryBreakdownList extends StatelessWidget {
  final Map<String, CategoryBreakdown> byCategory;
  final CategoryBreakdownKind kind;

  const CategoryBreakdownList({super.key, required this.byCategory, required this.kind});

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.values
        .where((c) => kind == CategoryBreakdownKind.expense ? c.expenseAmount > 0 : c.creditAmount > 0)
        .toList()
      ..sort((a, b) {
        final aAmt = kind == CategoryBreakdownKind.expense ? a.expenseAmount : a.creditAmount;
        final bAmt = kind == CategoryBreakdownKind.expense ? b.expenseAmount : b.creditAmount;
        return bAmt.compareTo(aAmt);
      });

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          kind == CategoryBreakdownKind.expense ? 'No expenses this period' : 'No credits this period',
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    final maxAmount = entries
        .map((c) => kind == CategoryBreakdownKind.expense ? c.expenseAmount : c.creditAmount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 2),
          child: Text('Category Breakdown',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
        for (final c in entries)
          _CategoryRow(
            entry: c,
            amount: kind == CategoryBreakdownKind.expense ? c.expenseAmount : c.creditAmount,
            count: kind == CategoryBreakdownKind.expense ? c.expenseCount : c.creditCount,
            fraction: maxAmount > 0
                ? (kind == CategoryBreakdownKind.expense ? c.expenseAmount : c.creditAmount) / maxAmount
                : 0,
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryBreakdown entry;
  final double amount;
  final int count;
  final double fraction;

  const _CategoryRow({required this.entry, required this.amount, required this.count, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (entry.bucket != null)
                      Text(entry.bucket!.displayName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${_amountFormat.format(amount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('$count txns', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

}
