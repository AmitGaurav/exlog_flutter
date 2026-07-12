import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/category_breakdown.dart';
import '../../domain/entities/period_summary.dart';
import '../../domain/services/analytics_calculator.dart';
import '../bloc/dashboard_state.dart';

final _amountFormat = NumberFormat('#,##,##0.00');
final _wholeAmountFormat = NumberFormat('#,##,##0');

const _spendingRankColors = [
  AppColors.primary,
  Color(0xFFAF52DE), // purple
  Color(0xFFFF9500), // orange
  Color(0xFF30B0C7), // teal
];
const _creditRankColors = [
  AppColors.income,
  Color(0xFF00C7BE), // mint
  Color(0xFF32ADE6), // cyan
  Color(0xFF30B0C7), // teal
];
const _yearRankColors = [
  Color(0xFF5856D6), // indigo
  Color(0xFFAF52DE), // purple
  AppColors.primary,
  Color(0xFF30B0C7), // teal
];

Color _rankColor(List<Color> palette, int index) =>
    index < palette.length ? palette[index] : AppColors.textTertiary;

/// Analytics tab — hero card + 5 collapsible sections, all computed
/// client-side from `DashboardBloc`'s cached monthly/yearly summaries via
/// [AnalyticsCalculator]. Replaces the old "Analytics coming soon" stub.
class AnalyticsContent extends StatefulWidget {
  final DashboardState state;
  const AnalyticsContent({super.key, required this.state});

  @override
  State<AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent> {
  final Set<String> _expanded = {};

  void _toggle(String key) => setState(() {
        if (_expanded.contains(key)) {
          _expanded.remove(key);
        } else {
          _expanded.add(key);
        }
      });

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.isAnalyticsLoading && state.monthlySummaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (state.analyticsError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(state.analyticsError!, style: const TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    if (!state.analyticsLoaded) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final overview = AnalyticsCalculator.monthlyOverview(state.monthlySummaries, now);
    final currentVsLastMonth = AnalyticsCalculator.currentVsLastMonth(state.monthlySummaries);
    final yearOnYear = AnalyticsCalculator.yearOnYear(state.yearlySummaries);

    PeriodSummary? currentYear;
    for (final y in state.yearlySummaries) {
      if (y.period == now.year.toString()) {
        currentYear = y;
        break;
      }
    }
    final topCategories = AnalyticsCalculator.topCategories(state.yearlySummaries, currentYear);
    final quickStats = AnalyticsCalculator.quickStats(
      yearlySummaries: state.yearlySummaries,
      currentYearSummary: currentYear,
      monthlyAvg: overview.monthlyAvg,
      allTimeSpendingCategories: topCategories.spendingAllTime,
      now: now,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(overview: overview),
        const SizedBox(height: 16),
        _AccordionSection(
          title: 'Monthly Expenses & Income',
          icon: Icons.receipt_long_outlined,
          isExpanded: _expanded.contains('monthly'),
          onToggle: () => _toggle('monthly'),
          child: _MonthlyExpensesIncome(overview: overview),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          title: 'Current vs Last Month',
          icon: Icons.swap_horiz_rounded,
          isExpanded: _expanded.contains('mom'),
          onToggle: () => _toggle('mom'),
          child: _CurrentVsLastMonthView(data: currentVsLastMonth),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          title: 'Year-on-Year Expenses',
          icon: Icons.calendar_month_outlined,
          isExpanded: _expanded.contains('yoy'),
          onToggle: () => _toggle('yoy'),
          child: _YearOnYearView(data: yearOnYear),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          title: 'Top Categories',
          icon: Icons.pie_chart_outline,
          isExpanded: _expanded.contains('topcat'),
          onToggle: () => _toggle('topcat'),
          child: _TopCategoriesView(data: topCategories),
        ),
        const SizedBox(height: 12),
        _AccordionSection(
          title: 'Quick Stats',
          icon: Icons.grid_view_rounded,
          isExpanded: _expanded.contains('quick'),
          onToggle: () => _toggle('quick'),
          child: _QuickStatsGrid(stats: quickStats),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final MonthlyOverview overview;
  const _HeroCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4DA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last 12 Months', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('₹${_wholeAmountFormat.format(overview.totalExpense)}',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.bar_chart_rounded, color: Colors.white),
                    const SizedBox(height: 4),
                    Text('${overview.txnCount} txns', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    icon: Icons.trending_flat,
                    value: '₹${_amountFormat.format(overview.monthlyAvg)}',
                    label: 'Monthly Avg',
                  ),
                ),
                const _HeroDivider(),
                Expanded(
                  child: _HeroStat(
                    icon: Icons.arrow_upward,
                    value: overview.highest == null ? '₹0' : '₹${_amountFormat.format(overview.highest!.amount)}',
                    label: overview.highest?.label ?? '—',
                  ),
                ),
                const _HeroDivider(),
                Expanded(
                  child: _HeroStat(
                    icon: Icons.arrow_downward,
                    value: overview.lowest == null ? '₹0' : '₹${_amountFormat.format(overview.lowest!.amount)}',
                    label: overview.lowest?.label ?? '—',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 40, child: VerticalDivider(color: AppColors.divider));
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AccordionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _AccordionSection({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.textPrimary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _MonthlyExpensesIncome extends StatelessWidget {
  final MonthlyOverview overview;
  const _MonthlyExpensesIncome({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < overview.rows.length; i++) ...[
          _MonthRowView(row: overview.rows[i], colorIndex: i - 1),
          if (i < overview.rows.length - 1) const Divider(height: 20, color: AppColors.divider),
        ],
        const Divider(height: 24, color: AppColors.divider),
        Row(
          children: [
            _FooterDot(color: AppColors.expense, label: 'Spent: ₹${_amountFormat.format(overview.totalSpent)}'),
            const SizedBox(width: 14),
            _FooterDot(color: AppColors.income, label: 'Earned: ₹${_amountFormat.format(overview.totalEarned)}'),
            const Spacer(),
            Text('Net: ₹${_amountFormat.format(overview.totalNet)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: overview.totalNet >= 0 ? AppColors.income : AppColors.expense)),
          ],
        ),
      ],
    );
  }
}

class _FooterDot extends StatelessWidget {
  final Color color;
  final String label;
  const _FooterDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MonthRowView extends StatelessWidget {
  final MonthRow row;
  final int colorIndex;
  const _MonthRowView({required this.row, required this.colorIndex});

  Color get _barColor {
    if (row.isCurrent) return AppColors.primary;
    const colors = [Color(0xFF5856D6), Color(0xFFAF52DE), AppColors.primary, Color(0xFF30B0C7)];
    if (colorIndex >= 0 && colorIndex < colors.length) return colors[colorIndex];
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(row.label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: row.isCurrent ? AppColors.primary : AppColors.textPrimary)),
            if (row.isCurrent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                child: const Text('CURRENT', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
            const Spacer(),
            Text('${row.net >= 0 ? '+' : '-'}₹${_amountFormat.format(row.net.abs())}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: row.net >= 0 ? AppColors.income : AppColors.expense)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.arrow_downward, size: 12, color: AppColors.expense),
            const SizedBox(width: 4),
            Text('₹${_amountFormat.format(row.expenseAmount)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_upward, size: 12, color: AppColors.income),
            const SizedBox(width: 4),
            Text('₹${_amountFormat.format(row.creditAmount)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const Spacer(),
            Text('${row.expenseCount + row.creditCount} txns', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: row.barFraction.clamp(0, 1),
            minHeight: 5,
            backgroundColor: AppColors.divider,
            color: _barColor,
          ),
        ),
      ],
    );
  }
}

class _CurrentVsLastMonthView extends StatelessWidget {
  final CurrentVsLastMonth data;
  const _CurrentVsLastMonthView({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.isIncrease ? AppColors.expense : AppColors.income;
    final icon = data.isIncrease ? Icons.trending_up : Icons.trending_down;
    final sign = data.percentChange >= 0 ? '+' : '';
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 6),
        Text('$sign${data.percentChange.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('This: ₹${_amountFormat.format(data.thisAmount)}', style: const TextStyle(fontSize: 13)),
            Text('Last: ₹${_amountFormat.format(data.lastAmount)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _YearOnYearView extends StatelessWidget {
  final YearOnYearResult data;
  const _YearOnYearView({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No data yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < data.rows.length; i++)
          _RankRow(
            rank: i + 1,
            color: _rankColor(_yearRankColors, i),
            title: data.rows[i].year,
            amount: data.rows[i].amount,
            count: data.rows[i].count,
            fraction: data.rows[i].barFraction,
          ),
        const Divider(height: 20, color: AppColors.divider),
        Text(
          'Total: ₹${_amountFormat.format(data.total)}   ${data.totalTxns} transactions   ${data.yearsOfData} years of data',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final Color color;
  final String title;
  final double amount;
  final int count;
  final double fraction;

  const _RankRow({
    required this.rank,
    required this.color,
    required this.title,
    required this.amount,
    required this.count,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${_amountFormat.format(amount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('($count)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesView extends StatelessWidget {
  final TopCategoriesResult data;
  const _TopCategoriesView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryRankList(
          title: 'Spending — Current Year',
          icon: Icons.pie_chart,
          colors: _spendingRankColors,
          entries: data.spendingCurrentYear,
          useCredit: false,
        ),
        const SizedBox(height: 16),
        _CategoryRankList(
          title: 'Spending — All Time',
          icon: Icons.donut_large,
          colors: _spendingRankColors,
          entries: data.spendingAllTime,
          useCredit: false,
        ),
        const SizedBox(height: 16),
        _CategoryRankList(
          title: 'Credits — Current Year',
          icon: Icons.arrow_circle_down,
          colors: _creditRankColors,
          entries: data.creditsCurrentYear,
          useCredit: true,
        ),
        const SizedBox(height: 16),
        _CategoryRankList(
          title: 'Credits — All Time',
          icon: Icons.arrow_circle_down_outlined,
          colors: _creditRankColors,
          entries: data.creditsAllTime,
          useCredit: true,
        ),
      ],
    );
  }
}

class _CategoryRankList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final List<CategoryBreakdown> entries;
  final bool useCredit;

  const _CategoryRankList({
    required this.title,
    required this.icon,
    required this.colors,
    required this.entries,
    required this.useCredit,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('No data yet', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      );
    }

    final maxAmount = entries
        .map((c) => useCredit ? c.creditAmount : c.expenseAmount)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < entries.length; i++)
          _RankRow(
            rank: i + 1,
            color: _rankColor(colors, i),
            title: entries[i].name,
            amount: useCredit ? entries[i].creditAmount : entries[i].expenseAmount,
            count: useCredit ? entries[i].creditCount : entries[i].expenseCount,
            fraction: maxAmount > 0 ? (useCredit ? entries[i].creditAmount : entries[i].expenseAmount) / maxAmount : 0,
          ),
      ],
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final QuickStats stats;
  const _QuickStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cells = [
      (Icons.arrow_downward, AppColors.expense, '${stats.totalExpenseTxns}', 'Total Expense Txns'),
      (Icons.arrow_upward, AppColors.income, '${stats.totalCreditTxns}', 'Total Credit Txns'),
      (Icons.drag_handle, const Color(0xFFFF9500), '₹${_amountFormat.format(stats.avgPerTxn)}', 'Avg per Txn'),
      (Icons.show_chart, AppColors.primary, '₹${_wholeAmountFormat.format(stats.projectedYearly)}', 'Projected Yearly'),
      (Icons.star, const Color(0xFFAF52DE), stats.topCategoryName ?? '—', 'Top Category'),
      (Icons.calendar_today, const Color(0xFF30B0C7), '₹${_amountFormat.format(stats.monthlyAvg)}', 'Monthly Avg'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        for (final c in cells)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.$2.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: c.$2, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(c.$1, color: Colors.white, size: 16),
                ),
                const Spacer(),
                Text(c.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(c.$4, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}
