import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/add_edit_transaction_sheet.dart';
import '../widgets/export_sheet.dart';
import '../widgets/filter_sheet.dart';
import 'transaction_detail_page.dart';

final _amountFormat = NumberFormat('#,##,##0.00');

Color typeColor(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
      return AppColors.expense;
    case TransactionType.credit:
      return AppColors.income;
    case TransactionType.cashWithdrawal:
      return AppColors.cashWithdrawal;
    case TransactionType.selfTransfer:
      return AppColors.selfTransfer;
  }
}

IconData typeIcon(TransactionType type) {
  switch (type) {
    case TransactionType.expense:
    case TransactionType.cashWithdrawal:
      return Icons.arrow_downward;
    case TransactionType.credit:
      return Icons.arrow_upward;
    case TransactionType.selfTransfer:
      return Icons.swap_horiz;
  }
}

String formattedSignedAmount(Transaction transaction) {
  final sign = transaction.type == TransactionType.credit ? '+' : '-';
  return '$sign₹${_amountFormat.format(transaction.amount)}';
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(const TransactionLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddSheet(BuildContext context) {
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
        child: const AddEditTransactionSheet(),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, TransactionState state) {
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
        child: FilterSheet(initialFilter: state.filter, transactions: state.transactions),
      ),
    );
  }

  void _openExportSheet(BuildContext context, TransactionState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ExportSheet(transactions: state.transactions),
    );
  }

  void _openDetail(BuildContext context, Transaction transaction) {
    final transactionBloc = context.read<TransactionBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: transactionBloc),
            BlocProvider.value(value: categoryBloc),
          ],
          child: TransactionDetailPage(transaction: transaction),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Transaction transaction) {
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
              context.read<TransactionBloc>().add(TransactionDeleteRequested(transaction.id!));
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
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listenWhen: (prev, cur) => cur.error != null && cur.error != prev.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: AppColors.expense),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, state),
              SliverToBoxAdapter(child: _buildSearchAndFilters(context, state)),
              if (state.status == TransactionStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.filteredTransactions.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(onAddTap: () => _openAddSheet(context)),
                )
              else
                _buildTransactionList(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, TransactionState state) {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundGray,
      pinned: true,
      expandedHeight: 96,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.ios_share, size: 22, color: AppColors.textPrimary),
        onPressed: () => _openExportSheet(context, state),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add, size: 28, color: AppColors.textPrimary),
          onPressed: () => _openAddSheet(context),
        ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 12),
        title: Text(
          'Transactions',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, TransactionState state) {
    final filter = state.filter;
    final hasActiveFilters = filter.dateRange != DateRangeOption.thisMonth ||
        filter.type != null ||
        filter.categoryId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => context.read<TransactionBloc>().add(TransactionSearchChanged(v)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Date: ${_dateRangeLabel(filter)}',
                selected: true,
                onTap: () => _openFilterSheet(context, state),
                onClear: filter.dateRange == DateRangeOption.thisMonth
                    ? null
                    : () => context.read<TransactionBloc>().add(
                          TransactionFilterChanged(filter.copyWith(
                            dateRange: DateRangeOption.thisMonth,
                            clearSelectedYear: true,
                            clearCustomRange: true,
                          )),
                        ),
              ),
              _FilterChip(
                label: filter.activeFilterCount > 0 ? 'Filters (${filter.activeFilterCount})' : 'Filters',
                selected: false,
                onTap: () => _openFilterSheet(context, state),
              ),
              if (hasActiveFilters)
                _FilterChip(
                  label: 'Clear All',
                  selected: false,
                  onTap: () => context.read<TransactionBloc>().add(const TransactionFiltersCleared()),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel(TransactionFilter filter) {
    switch (filter.dateRange) {
      case DateRangeOption.specificYear:
        return '${filter.selectedYear ?? DateTime.now().year}';
      case DateRangeOption.customRange:
        if (filter.customStart == null || filter.customEnd == null) return 'Custom Range';
        final fmt = DateFormat('MMM d, yyyy');
        return '${fmt.format(filter.customStart!)} – ${fmt.format(filter.customEnd!)}';
      default:
        return filter.dateRange.label;
    }
  }

  Widget _buildTransactionList(BuildContext context, TransactionState state) {
    final groups = state.groupedByDay;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, sectionIndex) {
          final entry = groups[sectionIndex];
          return _DaySection(
            label: entry.key,
            transactions: entry.value,
            onTap: (t) => _openDetail(context, t),
            onDelete: (t) => _confirmDelete(context, t),
          );
        },
        childCount: groups.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.move_to_inbox_outlined, size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No transactions found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first transaction or adjust filters',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: const Icon(Icons.add_circle, size: 20),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.cancel, size: 16, color: selected ? Colors.white : AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day section + transaction tile
// ─────────────────────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  final String label;
  final List<Transaction> transactions;
  final ValueChanged<Transaction> onTap;
  final ValueChanged<Transaction> onDelete;

  const _DaySection({
    required this.label,
    required this.transactions,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < transactions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 66, color: AppColors.divider),
                  _TransactionTile(
                    transaction: transactions[i],
                    onTap: () => onTap(transactions[i]),
                    onDelete: () => onDelete(transactions[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = typeColor(transaction.type);
    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(12)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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
                    Text(
                      transaction.payee,
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (transaction.categoryName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              transaction.categoryName!,
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMMM yyyy').format(transaction.timestamp),
                          style: AppTextStyles.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedSignedAmount(transaction),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
