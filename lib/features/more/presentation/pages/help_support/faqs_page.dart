import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import 'help_support_page.dart' show kSupportEmail;

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  final Set<int> _expanded = {};

  static const _faqs = [
    (
      'How does ExLog access my SMS messages?',
      'ExLog uses Android SMS permissions to read transaction SMS messages from your bank. We only access SMS '
          'messages that contain transaction information and never store or transmit the raw SMS content. All '
          'processing happens securely on your device.',
    ),
    (
      'Is my financial data secure?',
      'Absolutely! ExLog uses bank-level security with AES-256 encryption for all data storage. Your information '
          'is stored securely in Firebase with strict access controls. We never share your data with third '
          'parties, and you can delete your data at any time.',
    ),
    (
      'Which banks are supported?',
      'ExLog supports transaction SMS from all major Indian banks including HDFC, ICICI, SBI, Axis, Kotak, and '
          "more. Our AI-powered parser can understand various SMS formats. If your bank isn't working perfectly, "
          "contact support and we'll add specific parsing rules.",
    ),
    (
      "What's the difference between Free and Premium?",
      'Free tier includes: 10 SMS imports/month, 5 exports/month, 3 active reminders, and 5 custom categories. '
          'Premium (₹99/month, ₹999/year, or ₹4,999 lifetime) offers unlimited access to all features including '
          'unlimited imports, exports, reminders, categories, and priority support.',
    ),
    (
      'Can I import my historical transactions?',
      "Yes! Use the 'Import Historical Data' feature in Settings to bulk import past transaction SMS messages. "
          'This is perfect for building your complete financial history when you first start using ExLog.',
    ),
    (
      'How accurate is the AI SMS parser?',
      'Our AI parser has 95%+ accuracy across supported banks. It uses advanced natural language processing to '
          'extract amount, date, payee, transaction type, and payment method. You can always manually edit any '
          'transaction if needed.',
    ),
    (
      'Can I categorize transactions automatically?',
      "Yes! ExLog offers smart categorization through Payee Mappings. Set up rules like 'Amazon → Shopping' or "
          "'Swiggy → Food & Dining', and future transactions from these payees will be automatically categorized.",
    ),
    (
      'What are transaction edit restrictions?',
      'Edit restrictions help maintain data integrity by controlling when transactions can be modified. Options '
          'include: No Restrictions, Daily, Weekly, Monthly, or Yearly. Set this in Settings based on your '
          'preference.',
    ),
    (
      'How do I set up recurring payment reminders?',
      "Go to the Reminders tab, tap '+', enter the reminder details (name, amount, category), and choose the "
          "repeat interval (Monthly, Quarterly, Half Yearly, Yearly, or Custom). You'll receive notifications "
          'before the due date.',
    ),
    (
      'Can I export my transaction data?',
      'Yes! Use the Export feature to generate CSV files of your transactions. Choose from monthly exports, '
          'yearly summaries, or custom date ranges. Perfect for tax filing, accounting, or personal analysis in '
          'Excel or Google Sheets.',
    ),
    (
      'What are self-transfer names?',
      'Self-transfer names help ExLog identify transactions between your own accounts (like transferring money '
          "from savings to checking). Add your name variations in Settings so these transfers aren't counted as "
          'expenses.',
    ),
    (
      'How do categories and buckets work?',
      'ExLog organizes expenses into buckets like Daily, Weekly, Monthly, Quarterly, and Yearly. You can create '
          'custom categories within these buckets and track spending patterns by both category and bucket.',
    ),
    (
      'Can I use ExLog offline?',
      'ExLog requires an internet connection for AI parsing and data sync. However, you can view previously '
          'synced transactions offline. Any changes made offline will sync automatically when you reconnect.',
    ),
    (
      'How do I restore my Premium subscription?',
      "If you purchased Premium on another device or after reinstalling the app, go to Profile → Subscription "
          "Status → 'Restore Purchases'. Your subscription will be verified with Google Play and restored "
          'automatically.',
    ),
    (
      'Can I share my financial data with family?',
      'Currently, ExLog is designed for individual use. Family sharing and multi-user accounts are planned for '
          'a future update. Each user needs their own account for privacy and security.',
    ),
    (
      'What payment methods are tracked?',
      'ExLog tracks all payment methods mentioned in bank SMS: Credit Cards, Debit Cards, UPI (Google Pay, '
          'PhonePe, Paytm), Net Banking, and Cash withdrawals. Each transaction shows the payment method used.',
    ),
    (
      'How do I delete my account and data?',
      'Go to Settings → Delete Account. This will permanently delete all your transactions, categories, '
          'reminders, and personal information from our servers. This action cannot be undone.',
    ),
    (
      'Why is my bank SMS not being parsed?',
      'Ensure ExLog has SMS permissions enabled in Android Settings. Also, check that the SMS is a transaction '
          'notification (not promotional). If the issue persists, contact support with a screenshot of the SMS '
          'format (with sensitive info redacted).',
    ),
    (
      'Can I customize the dashboard?',
      'The current dashboard shows monthly overview, category breakdown, spending trends, and top payees. While '
          "layout customization isn't available yet, you can adjust the time period and filter by categories.",
    ),
    (
      'How do I get support?',
      'Email us at $kSupportEmail or use the Contact Support option in the Help section. Premium users get '
          'priority support with response within 24 hours. We\'re here to help!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('FAQs', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help, color: AppColors.income, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Frequently Asked Questions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Find answers to common questions about ExLog',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  _FAQItem(
                    question: _faqs[i].$1,
                    answer: _faqs[i].$2,
                    isExpanded: _expanded.contains(i),
                    onTap: () => setState(() {
                      if (_expanded.contains(i)) {
                        _expanded.remove(i);
                      } else {
                        _expanded.add(i);
                      }
                    }),
                  ),
                  if (i < _faqs.length - 1) const Divider(height: 1, indent: 16, color: AppColors.divider),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                const Icon(Icons.mail, size: 44, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text('Still have questions?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  "We're here to help! Contact our support team and we'll get back to you as soon as possible.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:$kSupportEmail')),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isExpanded ? Icons.expand_circle_down : Icons.chevron_right,
                  color: isExpanded ? AppColors.income : AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 36),
                child: Text(answer, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
              ),
          ],
        ),
      ),
    );
  }
}
