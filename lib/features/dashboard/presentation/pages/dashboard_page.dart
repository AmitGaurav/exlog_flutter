import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/analytics_content.dart';
import '../widgets/category_breakdown_list.dart';
import '../widgets/credit_transactions_list.dart';
import '../widgets/greeting_card.dart';
import '../widgets/mini_stat_card.dart';
import '../widgets/period_tab_bar.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _expensesExpanded = false;
  bool _creditsExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final displayName = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.displayName ?? '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context.read<DashboardBloc>().add(const DashboardLoadRequested());
            // Wait briefly so the refresh indicator is visible
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  GreetingCard(displayName: displayName),
                  const SizedBox(height: 16),
                  PeriodTabBar(
                    selected: state.selectedTab,
                    onTabSelected: (tab) => context
                        .read<DashboardBloc>()
                        .add(DashboardTabChanged(tab)),
                  ),
                  const SizedBox(height: 16),
                  if (state.selectedTab == DashboardTab.analytics)
                    AnalyticsContent(state: state)
                  else
                    _SummaryContent(
                      state: state,
                      expensesExpanded: _expensesExpanded,
                      creditsExpanded: _creditsExpanded,
                      onToggleExpenses: () =>
                          setState(() => _expensesExpanded = !_expensesExpanded),
                      onToggleCredits: () =>
                          setState(() => _creditsExpanded = !_creditsExpanded),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final DashboardState state;
  final bool expensesExpanded;
  final bool creditsExpanded;
  final VoidCallback onToggleExpenses;
  final VoidCallback onToggleCredits;

  const _SummaryContent({
    required this.state,
    required this.expensesExpanded,
    required this.creditsExpanded,
    required this.onToggleExpenses,
    required this.onToggleCredits,
  });

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final expense = summary?.expenseAmount ?? 0.0;
    final credit = summary?.creditAmount ?? 0.0;
    final cash = summary?.cashWithdrawalAmount ?? 0.0;
    final transfer = summary?.selfTransferAmount ?? 0.0;

    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 48),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Text(
            state.error!,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Total Expenses
        SummaryCard(
          label: AppStrings.totalExpenses,
          amount: expense,
          indicatorColor: AppColors.expense,
          indicatorIcon: Icons.arrow_upward_rounded,
          isExpanded: expensesExpanded,
          onToggle: onToggleExpenses,
        ),
        if (expensesExpanded) ...[
          const SizedBox(height: 12),
          CategoryBreakdownList(
            byCategory: summary?.byCategory ?? const {},
            kind: CategoryBreakdownKind.expense,
          ),
        ],
        const SizedBox(height: 12),
        // Mini cards row
        Row(
          children: [
            Expanded(
              child: MiniStatCard(
                label: AppStrings.cashWithdrawals,
                amount: cash,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cashWithdrawal.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.cashWithdrawal,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MiniStatCard(
                label: AppStrings.selfTransfers,
                amount: transfer,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.selfTransfer.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.selfTransfer,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Credits
        SummaryCard(
          label: AppStrings.credits,
          amount: credit,
          indicatorColor: AppColors.income,
          indicatorIcon: Icons.arrow_downward_rounded,
          isExpanded: creditsExpanded,
          onToggle: onToggleCredits,
        ),
        if (creditsExpanded) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final (start, end) = _periodBounds(state.selectedTab);
              return CreditTransactionsList(
                allTransactions: context.watch<TransactionBloc>().state.transactions,
                periodStart: start,
                periodEnd: end,
              );
            },
          ),
        ],
      ],
    );
  }

  (DateTime, DateTime) _periodBounds(DashboardTab tab) {
    final now = DateTime.now();
    if (tab == DashboardTab.thisYear) {
      return (DateTime(now.year), DateTime(now.year + 1));
    }
    return (DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
  }
}
