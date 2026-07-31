import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

/// Shown in place of the old "Upgrade to Premium" prompts now that ExLog is
/// free for everyone — a purely optional support appeal, never a paywall.
class BuyMeACoffeeContent extends StatelessWidget {
  static const upiId = 'c2902@ybl';

  const BuyMeACoffeeContent({super.key});

  void _copyUpiId(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UPI ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCC00).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('☕', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ExLog is free for everyone',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text('No subscriptions, no limits',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 16),
        const Text(
          'If ExLog saves you time, consider buying me a coffee. '
          'It\'s completely optional and helps keep the app free.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/buy_me_a_coffee_qr.jpeg',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Scan with any UPI app (PhonePe, GPay, Paytm...)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _copyUpiId(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(upiId, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal wrapper around [BuyMeACoffeeContent] for places (e.g. the Settings
/// subscription row) that previously opened FreeTierUpgradeSheet.
class BuyMeACoffeeSheet extends StatelessWidget {
  const BuyMeACoffeeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
            const BuyMeACoffeeContent(),
          ],
        ),
      ),
    );
  }
}
