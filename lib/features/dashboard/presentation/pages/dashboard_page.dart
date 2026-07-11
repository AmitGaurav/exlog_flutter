import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
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
                    _AnalyticsPlaceholder()
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
      ],
    );
  }
}

class _AnalyticsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 56, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'Analytics coming soon',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
