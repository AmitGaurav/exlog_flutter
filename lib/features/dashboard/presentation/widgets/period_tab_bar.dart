import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/dashboard_event.dart';

class PeriodTabBar extends StatelessWidget {
  final DashboardTab selected;
  final ValueChanged<DashboardTab> onTabSelected;

  const PeriodTabBar({
    super.key,
    required this.selected,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabItem(
            label: AppStrings.thisMonth,
            isActive: selected == DashboardTab.thisMonth,
            onTap: () => onTabSelected(DashboardTab.thisMonth),
          ),
          _TabItem(
            label: AppStrings.thisYear,
            isActive: selected == DashboardTab.thisYear,
            onTap: () => onTabSelected(DashboardTab.thisYear),
          ),
          _TabItem(
            label: AppStrings.analytics,
            isActive: selected == DashboardTab.analytics,
            onTap: () => onTabSelected(DashboardTab.analytics),
            icon: Icons.show_chart_rounded,
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
  final IconData? icon;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.tabActive : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: isActive
                      ? AppTextStyles.tabActive
                      : AppTextStyles.tabInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
