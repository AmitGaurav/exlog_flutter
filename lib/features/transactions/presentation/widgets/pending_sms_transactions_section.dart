import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/pending_sms_repository.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../pages/transactions_page.dart' show typeColor, typeIcon, formattedSignedAmount;

/// "Detected from SMS (N)" — Android-only auto-detect queue (no iOS analog).
/// Each row lets the user Approve (creates the real transaction) or Reject
/// (discards) an SMS-parsed draft before it ever becomes a real transaction.
class PendingSmsTransactionsSection extends StatefulWidget {
  const PendingSmsTransactionsSection({super.key});

  @override
  State<PendingSmsTransactionsSection> createState() => _PendingSmsTransactionsSectionState();
}

class _PendingSmsTransactionsSectionState extends State<PendingSmsTransactionsSection> {
  final _repository = sl<PendingSmsRepository>();
  final Set<String> _busyIds = {};

  Future<void> _approve(Transaction pending) async {
    setState(() => _busyIds.add(pending.id!));
    try {
      await _repository.approve(pending);
      // approve() creates the transaction directly via the repository
      // (bypassing TransactionBloc, since the pending queue has its own
      // stream), so the main list needs an explicit reload to pick it up.
      if (mounted) context.read<TransactionBloc>().add(const TransactionLoadRequested());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve transaction.'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(pending.id));
    }
  }

  Future<void> _reject(Transaction pending) async {
    setState(() => _busyIds.add(pending.id!));
    try {
      await _repository.reject(pending.id!);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject transaction.'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(pending.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Transaction>>(
      stream: _repository.watchPending(),
      builder: (context, snapshot) {
        final pending = snapshot.data ?? const <Transaction>[];
        if (pending.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sms_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Detected from SMS (${pending.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < pending.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 66, color: AppColors.divider),
                      _PendingRow(
                        transaction: pending[i],
                        busy: _busyIds.contains(pending[i].id),
                        onApprove: () => _approve(pending[i]),
                        onReject: () => _reject(pending[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PendingRow extends StatelessWidget {
  final Transaction transaction;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRow({
    required this.transaction,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final color = typeColor(transaction.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(typeIcon(transaction.type), size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.payee, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (transaction.bankName != null) transaction.bankName!,
                    DateFormat('d MMM yyyy').format(transaction.timestamp),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formattedSignedAmount(transaction), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.income),
              onPressed: onApprove,
              tooltip: 'Approve',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.expense),
              onPressed: onReject,
              tooltip: 'Reject',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
