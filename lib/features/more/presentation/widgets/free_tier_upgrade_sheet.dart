import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/purchase_plan.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Real Google Play Billing purchase flow. Plan rows are selectable
/// (defaulting to Yearly); prices come live from Play Console once products
/// load, falling back to the static recommended pricing if the store can't
/// be reached (offline/dev/no Play Console products yet). See
/// PLAY_BILLING_SETUP.md for the exact product IDs this is coded against.
class FreeTierUpgradeSheet extends StatefulWidget {
  const FreeTierUpgradeSheet({super.key});

  @override
  State<FreeTierUpgradeSheet> createState() => _FreeTierUpgradeSheetState();
}

class _FreeTierUpgradeSheetState extends State<FreeTierUpgradeSheet> {
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

  // Fallback labels shown until (or unless) live Play Console prices load —
  // installs-first pricing: low impulse-buy monthly, a heavily-discounted
  // yearly anchor plan, and a one-time lifetime option (India has strong
  // subscription fatigue — a real lifetime tier converts well here).
  static const _fallbackPrices = {
    PurchasePlan.monthly: ('₹49', 'per month'),
    PurchasePlan.yearly: ('₹299', 'per year · BEST VALUE · SAVE 49%'),
    PurchasePlan.lifetime: ('₹799', 'one-time'),
  };

  final _repository = sl<PurchaseRepository>();
  StreamSubscription<PurchaseResult>? _resultsSub;

  PurchasePlan _selected = PurchasePlan.yearly;
  Map<PurchasePlan, ProductDetails> _products = {};
  bool _loadingProducts = true;
  bool _purchasing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _resultsSub = _repository.results.listen(_onResult);
  }

  @override
  void dispose() {
    _resultsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final available = await _repository.isAvailable();
      if (!available) {
        setState(() => _loadingProducts = false);
        return;
      }
      final products = await _repository.queryProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loadingProducts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  void _onResult(PurchaseResult result) {
    if (!mounted) return;
    switch (result.status) {
      case PurchaseResultStatus.pending:
        setState(() {
          _purchasing = true;
          _errorMessage = null;
        });
      case PurchaseResultStatus.success:
        setState(() {
          _purchasing = false;
          _errorMessage = null;
          _successMessage = 'Purchase successful! Welcome to Premium ✅';
        });
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.of(context).pop();
        });
      case PurchaseResultStatus.canceled:
        setState(() {
          _purchasing = false;
        });
      case PurchaseResultStatus.error:
        setState(() {
          _purchasing = false;
          _errorMessage = result.message ?? 'Something went wrong with the purchase. Please try again.';
        });
    }
  }

  Future<void> _upgradeNow() async {
    final details = _products[_selected];
    if (details == null) {
      setState(() => _errorMessage =
          'This plan isn\'t available right now. Please check your connection and try again.');
      return;
    }
    setState(() {
      _purchasing = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await _repository.buy(_selected, details);
      // Result (success/error/pending) arrives asynchronously via _onResult.
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await _repository.restorePurchases();
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

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
            _PlanRow(
              name: 'Free',
              price: '₹0',
              period: '',
              selected: false,
              onTap: null,
            ),
            for (final plan in [PurchasePlan.monthly, PurchasePlan.yearly, PurchasePlan.lifetime])
              _PlanRow(
                name: plan.displayName,
                price: _products[plan]?.price ?? _fallbackPrices[plan]!.$1,
                period: _fallbackPrices[plan]!.$2,
                selected: _selected == plan,
                onTap: _purchasing ? null : () => setState(() => _selected = plan),
              ),
            if (_loadingProducts) ...[
              const SizedBox(height: 8),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.expense.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.expense, fontSize: 13)),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.income.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_successMessage!, style: const TextStyle(color: AppColors.income, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _purchasing ? null : _upgradeNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _purchasing ? null : _restore,
              child: const Text('Restore Purchases'),
            ),
          ],
        ),
      ),
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
  final bool selected;
  final VoidCallback? onTap;
  const _PlanRow({
    required this.name,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(20) : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            if (onTap != null) ...[
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
            ],
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
      ),
    );
  }
}
