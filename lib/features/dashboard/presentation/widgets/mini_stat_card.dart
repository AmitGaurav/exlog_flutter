import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Small stat card for Cash Withdrawals / Self Transfers.
class MiniStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Widget icon;

  const MiniStatCard({
    super.key,
    required this.label,
    required this.amount,
    this.currency = '₹',
    required this.icon,
  });

  String _formatAmount(double v) {
    if (v == v.truncate()) return '$currency${v.toInt()}';
    return '$currency${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(_formatAmount(amount), style: AppTextStyles.amountSmall),
        ],
      ),
    );
  }
}
