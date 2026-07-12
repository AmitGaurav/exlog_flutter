import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  static const _steps = [
    ('1', 'Automatic SMS Detection',
        'ExLog monitors your SMS inbox for bank transaction notifications. When you receive a transaction SMS '
            'from your bank, the app automatically detects it.',
        Icons.mail_outline, AppColors.primary),
    ('2', 'AI-Powered Parsing',
        'Our advanced AI engine extracts key information from the SMS: amount, date, payee name, transaction '
            'type (debit/credit), and payment method. Works with multiple banks and card providers.',
        Icons.auto_awesome, Color(0xFF5856D6)),
    ('3', 'Smart Categorization',
        'Transactions are automatically categorized based on payee mappings and intelligent rules. You can '
            'create custom categories and set up automatic payee mappings for recurring expenses.',
        Icons.sell_outlined, AppColors.income),
    ('4', 'Real-Time Dashboard',
        'View your financial data on a beautiful dashboard with monthly summaries, category breakdowns, '
            'spending trends, and top payees. All data updates in real-time.',
        Icons.bar_chart, Color(0xFFFF9500)),
    ('5', 'Smart Reminders',
        'Set up recurring reminders for bills, EMIs, and subscriptions. Get notifications before due dates '
            'to never miss a payment.',
        Icons.notifications_outlined, AppColors.expense),
    ('6', 'Export & Analysis',
        'Export your transaction data as CSV for detailed analysis. Generate monthly or custom date range '
            'reports with comprehensive financial insights.',
        Icons.ios_share, Color(0xFF5856D6)),
  ];

  static const _keyFeatures = [
    ('AI SMS Parser', Icons.psychology_outlined, Color(0xFFFF2D55), [
      'Supports multiple AI providers (GPT-4, Claude, Gemini)',
      'Learns from your transaction patterns',
      'Handles various bank SMS formats',
      '95%+ parsing accuracy',
    ]),
    ('Smart Categories', Icons.folder_open_outlined, Color(0xFF30B0C7), [
      'Pre-defined expense buckets (Needs, Wants, Savings)',
      'Create unlimited custom categories (Premium)',
      'Automatic payee-to-category mapping',
      'Visual category-wise analytics',
    ]),
    ('Transaction Management', Icons.manage_search, AppColors.primary, [
      'View all transactions in chronological order',
      'Filter by date, category, type, or payee',
      'Edit transaction details manually',
      'Configurable edit restrictions for data integrity',
    ]),
    ('Reminders', Icons.event_note_outlined, Color(0xFFFF9500), [
      'Set one-time or recurring reminders',
      'Link reminders to specific categories',
      'Get push notifications at scheduled times',
      'Track payment history',
    ]),
  ];

  static const _dataFlow = [
    'Bank SMS Received',
    'SMS Import (Manual/Auto)',
    'AI Parsing Engine',
    'Transaction Created',
    'Category Assignment',
    'Dashboard Update',
    'Analytics & Reports',
  ];

  static const _security = [
    'All data encrypted with industry-standard AES-256',
    'Secure cloud storage with Firebase',
    'We never access your bank accounts or cards',
    'SMS processing happens on your device',
    'GDPR compliant data handling',
  ];

  static const _tips = [
    'Import historical SMS messages on first setup for complete financial history',
    'Set up payee mappings for frequently used merchants to auto-categorize future transactions',
    'Review your dashboard weekly to track spending patterns and identify savings opportunities',
    "Use custom categories to track specific goals (e.g., 'Vacation Fund', 'Home Renovation')",
    'Export monthly reports for tax preparation and financial planning',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('How It Works', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Icon(Icons.lightbulb, color: Color(0xFFFF9500), size: 24),
                    SizedBox(width: 8),
                    Text('How ExLog Works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ExLog is your intelligent financial companion that automates expense tracking through smart '
                  'SMS parsing and powerful analytics. Here\'s how it works:',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final s in _steps)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: s.$5, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s.$4, color: Colors.white, size: 16),
                        Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(s.$3, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _SectionCard(
            icon: Icons.star,
            iconColor: const Color(0xFFFFCC00),
            title: 'Key Features',
            child: Column(
              children: [
                for (var i = 0; i < _keyFeatures.length; i++) ...[
                  _FeatureDetail(
                    title: _keyFeatures[i].$1,
                    icon: _keyFeatures[i].$2,
                    color: _keyFeatures[i].$3,
                    points: _keyFeatures[i].$4,
                  ),
                  if (i < _keyFeatures.length - 1) const Divider(height: 24, color: AppColors.divider),
                ],
              ],
            ),
          ),
          _SectionCard(
            icon: Icons.call_split,
            iconColor: const Color(0xFF5856D6),
            title: 'Data Flow',
            child: Column(
              children: [
                for (var i = 0; i < _dataFlow.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.avatarPurple]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_dataFlow[i],
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  if (i < _dataFlow.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Icon(Icons.arrow_downward, color: AppColors.primary),
                    ),
                ],
              ],
            ),
          ),
          _SectionCard(
            icon: Icons.lock_outline,
            iconColor: AppColors.income,
            title: 'Security & Privacy',
            child: Column(
              children: [
                for (final s in _security)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.income, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _SectionCard(
            icon: Icons.tips_and_updates,
            iconColor: const Color(0xFFFFCC00),
            title: 'Pro Tips',
            child: Column(
              children: [
                for (var i = 0; i < _tips.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00).withValues(alpha: 0.3), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('${i + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF9500))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_tips[i], style: const TextStyle(fontSize: 14))),
                      ],
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FeatureDetail extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> points;

  const _FeatureDetail({required this.title, required this.icon, required this.color, required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppColors.income, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ],
            ),
          ),
      ],
    );
  }
}
