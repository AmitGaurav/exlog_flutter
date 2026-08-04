import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../more/domain/services/edit_restriction_checker.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/add_edit_transaction_sheet.dart';
import 'transactions_page.dart' show typeColor, formattedSignedAmount;

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  bool _checkEditable(BuildContext context, Transaction current) {
    final checker = sl<EditRestrictionChecker>();
    if (checker.isTransactionEditable(current)) return true;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cannot Edit'),
        content: Text(checker.getRestrictionMessage(current)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
    return false;
  }

  void _openEditSheet(BuildContext context, Transaction current) {
    if (!_checkEditable(context, current)) return;
    final transactionBloc = context.read<TransactionBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: transactionBloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: AddEditTransactionSheet(existing: current),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Transaction current) {
    if (!_checkEditable(context, current)) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              context.read<TransactionBloc>().add(TransactionDeleteRequested(current.id!));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final current = state.transactions.firstWhere(
          (t) => t.id == transaction.id,
          orElse: () => transaction,
        );
        return Scaffold(
          backgroundColor: AppColors.backgroundGray,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundGray,
            elevation: 0,
            title: const Text('Transaction Details', style: AppTextStyles.heading2),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                onPressed: () => _openEditSheet(context, current),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                onPressed: () => _confirmDelete(context, current),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionLabel('Details'),
              const SizedBox(height: 8),
              _DetailCard(rows: [
                _DetailRow('Payee', current.payee),
                _DetailRow('Amount', formattedSignedAmount(current), valueColor: typeColor(current.type)),
                _DetailRow('Type', current.type.displayName),
                _DetailRow('Date', DateFormat('d MMM yyyy, h:mm a').format(current.timestamp)),
                _DetailRow('Category', current.categoryName ?? 'Uncategorized'),
                if (current.bucket != null) _DetailRow('Bucket', current.bucket!.displayName),
                if (current.bankName != null && current.bankName!.isNotEmpty)
                  _DetailRow('Bank', current.bankName!),
                if (current.accountNumber != null && current.accountNumber!.isNotEmpty)
                  _DetailRow('Account', current.accountNumber!),
              ]),
              if (current.notes != null && current.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionLabel('Notes'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(current.notes!, style: AppTextStyles.body),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _DetailRow {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});
}

class _DetailCard extends StatelessWidget {
  final List<_DetailRow> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 14, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rows[i].label, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: rows[i].valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
