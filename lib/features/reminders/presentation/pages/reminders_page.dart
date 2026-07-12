import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';
import '../widgets/add_reminder_sheet.dart';

enum _ReminderTab { upcoming, overdue, paid }

final _amountFormat = NumberFormat('#,##,##0.00');

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  _ReminderTab _selectedTab = _ReminderTab.upcoming;

  @override
  void initState() {
    super.initState();
    context.read<ReminderBloc>().add(const ReminderLoadRequested());
  }

  void _openAddSheet(BuildContext context) {
    final reminderBloc = context.read<ReminderBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: reminderBloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: const AddReminderSheet(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Reminder reminder) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Delete "${reminder.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ReminderBloc>().add(ReminderDeleteRequested(reminder.id!));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmMarkAsPaid(BuildContext context, Reminder reminder) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: Text(
          "Are you sure you want to mark '${reminder.title}' as paid?"
          "${reminder.amount != null ? '\nAmount: ₹${_amountFormat.format(reminder.amount)}' : ''}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ReminderBloc>().add(ReminderMarkAsPaidRequested(reminder));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmUndoPayment(BuildContext context, Reminder reminder) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Undo Payment?'),
        content: Text(
          "This will mark '${reminder.title}' as unpaid and restore it to the upcoming reminders.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ReminderBloc>().add(ReminderUndoPaymentRequested(reminder));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? AppColors.expense : const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listenWhen: (prev, cur) =>
            (cur.error != null && cur.error != prev.error) ||
            (cur.successMessage != null && cur.successMessage != prev.successMessage),
        listener: (context, state) {
          if (state.error != null) {
            _showToast(context, state.error!, isError: true);
            context.read<ReminderBloc>().add(const ReminderErrorCleared());
          } else if (state.successMessage != null) {
            _showToast(context, state.successMessage!, isError: false);
            context.read<ReminderBloc>().add(const ReminderSuccessCleared());
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _ReminderTabBar(
                    selected: _selectedTab,
                    onSelected: (t) => setState(() => _selectedTab = t),
                  ),
                ),
              ),
              if (state.status == ReminderStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildList(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      pinned: true,
      expandedHeight: 96,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, size: 28, color: AppColors.textPrimary),
          onPressed: () => _openAddSheet(context),
        ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 12),
        title: Text(
          'Reminders',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  List<Reminder> _remindersForTab(ReminderState state) {
    switch (_selectedTab) {
      case _ReminderTab.upcoming:
        return state.upcomingReminders;
      case _ReminderTab.overdue:
        return state.overdueReminders;
      case _ReminderTab.paid:
        return state.paidReminders;
    }
  }

  Widget _buildList(BuildContext context, ReminderState state) {
    final reminders = _remindersForTab(state);
    if (reminders.isEmpty) {
      return SliverFillRemaining(child: _EmptyState(tab: _selectedTab));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Column(
          children: [
            _ReminderCard(
              reminder: reminders[index],
              onDelete: () => _confirmDelete(context, reminders[index]),
              onMarkAsPaid: () => _confirmMarkAsPaid(context, reminders[index]),
              onUndoPayment: () => _confirmUndoPayment(context, reminders[index]),
            ),
            const Divider(height: 1, color: AppColors.divider),
          ],
        ),
        childCount: reminders.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderTabBar extends StatelessWidget {
  final _ReminderTab selected;
  final ValueChanged<_ReminderTab> onSelected;

  const _ReminderTabBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Upcoming',
            isActive: selected == _ReminderTab.upcoming,
            onTap: () => onSelected(_ReminderTab.upcoming),
          ),
          _TabItem(
            label: 'Overdue',
            isActive: selected == _ReminderTab.overdue,
            onTap: () => onSelected(_ReminderTab.overdue),
          ),
          _TabItem(
            label: 'Paid',
            isActive: selected == _ReminderTab.paid,
            onTap: () => onSelected(_ReminderTab.paid),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _ReminderTab tab;
  const _EmptyState({required this.tab});

  String get _title {
    switch (tab) {
      case _ReminderTab.upcoming:
        return 'No Upcoming Reminders';
      case _ReminderTab.overdue:
        return 'No Overdue Reminders';
      case _ReminderTab.paid:
        return 'No Paid Reminders';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 72, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add a reminder',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminder card
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onUndoPayment;

  const _ReminderCard({
    required this.reminder,
    required this.onDelete,
    required this.onMarkAsPaid,
    required this.onUndoPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(reminder.id ?? reminder.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.expense,
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reminder.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                if (reminder.isOverdue)
                  const Icon(Icons.warning_rounded, color: AppColors.expense, size: 26)
                else if (reminder.isPaid)
                  const Icon(Icons.check_circle, color: AppColors.income, size: 26),
              ],
            ),
            if (reminder.amount != null) ...[
              const SizedBox(height: 6),
              Text(
                '₹${_amountFormat.format(reminder.amount)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM yyyy').format(reminder.nextDueDate),
                  style: AppTextStyles.bodySecondary,
                ),
                const Spacer(),
                const Icon(Icons.repeat, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(reminder.repeatType.displayName, style: AppTextStyles.bodySecondary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (reminder.isPaid)
                  ElevatedButton.icon(
                    onPressed: onUndoPayment,
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Undo Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cashWithdrawal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: onMarkAsPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Mark as Paid'),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 13,
                      color: reminder.isOverdue ? AppColors.expense : AppColors.textSecondary,
                      fontWeight: reminder.isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _statusText {
    if (reminder.isPaid) {
      final paidDate = reminder.lastPaidDate;
      return paidDate == null ? '' : 'Paid on ${DateFormat('d MMM yyyy').format(paidDate)}';
    }
    final days = reminder.daysUntilDue;
    if (days < 0) return '${-days} days overdue';
    if (days == 0) return 'Due today';
    return '$days days left';
  }
}
