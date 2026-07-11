import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Large expandable summary card (Total Expenses / Credits).
class SummaryCard extends StatefulWidget {
  final String label;
  final double amount;
  final String currency;
  final Color indicatorColor;
  final IconData indicatorIcon;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.currency = '₹',
    required this.indicatorColor,
    required this.indicatorIcon,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  String _formatAmount(double amount) {
    if (amount == amount.truncate()) {
      return '${widget.currency}${amount.toStringAsFixed(2)}';
    }
    return '${widget.currency}${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Indicator icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.indicatorColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.indicatorIcon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // Label + amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(widget.amount),
                    style: AppTextStyles.amountLarge,
                  ),
                ],
              ),
            ),
            // Expand/collapse chevron
            Icon(
              widget.isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
