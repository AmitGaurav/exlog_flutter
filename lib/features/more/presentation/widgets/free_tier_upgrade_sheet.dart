import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Static premium pricing/feature sheet — iOS's PremiumUpgradeView is backed
/// by a real StoreKit purchase flow; Android would need Google Play Billing
/// (a different SDK, no 1:1 iOS reference), so this phase ports the UI only.
/// "Upgrade"/"Restore Purchases" are no-ops, matching the existing stubbed
/// Free Tier banner precedent already used in Categories/Transactions/Reminders.
class FreeTierUpgradeSheet extends StatelessWidget {
  const FreeTierUpgradeSheet({super.key});

  static const _features = [
    ('Unlimited SMS Import', 'Import unlimited bank SMS messages', Icons.mail_outline),
    ('Unlimited Exports', 'Export transactions anytime', Icons.ios_share),
    ('Advanced Reports', 'Yearly reports & custom date ranges', Icons.bar_chart),
    ('Cloud Backup & Sync', 'Never lose your data', Icons.cloud_outlined),
    ('Unlimited Reminders', 'Set as many reminders as you need', Icons.notifications_outlined),
    ('Unlimited Categories', 'Create unlimited custom categories', Icons.folder_outlined),
    ('Multiple Accounts', 'Track multiple bank accounts', Icons.account_balance_outlined),
    ('Priority Support', 'Get help faster', Icons.support_agent),
  ];

  static const _plans = [
    ('Free', '₹0', ''),
    ('Monthly', '₹99', 'per month'),
    ('Yearly', '₹999', 'per year · BEST VALUE'),
    ('Lifetime', '₹4,999', 'one-time'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Icon(Icons.workspace_premium, size: 56, color: Color(0xFFFFCC00))),
            const SizedBox(height: 12),
            const Center(
              child: Text('Upgrade to Premium',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Unlock all features and supercharge your expense tracking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Premium Features',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            for (final f in _features) _FeatureRow(title: f.$1, description: f.$2, icon: f.$3),
            const SizedBox(height: 24),
            const Text('Pricing Plans',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            for (final p in _plans) _PlanRow(name: p.$1, price: p.$2, period: p.$3),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showComingSoon(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _showComingSoon(context),
              child: const Text('Restore Purchases'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium purchases are coming soon.')),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  const _FeatureRow({required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  const _PlanRow({required this.name, required this.price, required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (period.isNotEmpty)
                  Text(period, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }
}
