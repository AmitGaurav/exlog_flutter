import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const _features = [
    ('Automatic SMS Parsing', 'Intelligent AI-powered extraction of transaction details from bank SMS messages',
        Icons.mail_outline, AppColors.primary),
    ('Smart Categorization', 'Automatically organize expenses into meaningful categories with custom rules',
        Icons.pie_chart_outline, AppColors.income),
    ('Visual Analytics', 'Beautiful dashboards and charts to understand your spending patterns',
        Icons.bar_chart, Color(0xFFFF9500)),
    ('Smart Reminders', 'Never miss a bill payment with intelligent recurring reminders',
        Icons.notifications_outlined, AppColors.expense),
    ('Export & Reports', 'Generate detailed financial reports and export data for analysis',
        Icons.ios_share, Color(0xFF5856D6)),
    ('Privacy First', 'Bank-level security with end-to-end encryption for your financial data',
        Icons.lock_outline, Color(0xFFFF2D55)),
  ];

  static const _values = [
    ('Privacy & Security', Icons.shield_outlined, AppColors.primary),
    ('Innovation & Intelligence', Icons.auto_awesome, Color(0xFF5856D6)),
    ('User-Centric Design', Icons.pan_tool_outlined, AppColors.income),
    ('Financial Empowerment', Icons.trending_up, Color(0xFFFF9500)),
    ('Simplicity & Clarity', Icons.eco_outlined, Color(0xFF30B0C7)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.avatarPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 15),
                const Text('ExLog', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Expense Logger & Financial Manager',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _Card(
            icon: Icons.remove_red_eye_outlined,
            iconColor: AppColors.primary,
            title: 'Our Vision',
            child: const Text(
              'To empower individuals and families with intelligent financial management tools that make '
              'expense tracking effortless, insightful, and actionable.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          _Card(
            icon: Icons.track_changes_outlined,
            iconColor: AppColors.income,
            title: 'Our Mission',
            child: const Text(
              'ExLog is committed to democratizing financial awareness by providing cutting-edge technology '
              'that automatically tracks, categorizes, and analyzes your expenses. We believe everyone deserves '
              'clear insights into their financial health without the complexity of traditional expense management.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          _Card(
            icon: Icons.card_giftcard,
            iconColor: Color(0xFF5856D6),
            title: 'What We Offer',
            child: Column(
              children: [
                for (var i = 0; i < _features.length; i++) ...[
                  _FeatureItem(
                    title: _features[i].$1,
                    description: _features[i].$2,
                    icon: _features[i].$3,
                    color: _features[i].$4,
                  ),
                  if (i < _features.length - 1) const Divider(height: 20, color: AppColors.divider),
                ],
              ],
            ),
          ),
          _Card(
            icon: Icons.favorite_border,
            iconColor: AppColors.expense,
            title: 'Core Values',
            child: Column(
              children: [
                for (final v in _values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(v.$2, color: v.$3, size: 20),
                        const SizedBox(width: 12),
                        Text(v.$1, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _Card(
            icon: Icons.groups_outlined,
            iconColor: Color(0xFF5856D6),
            title: 'The Team',
            child: const Text(
              'ExLog is built by a passionate team of developers, designers, and financial experts who believe '
              'in making financial management accessible to everyone. We combine decades of experience in '
              'fintech, mobile development, and user experience design to create a product that truly serves '
              'your needs.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Column(
              children: [
                Text('Get in Touch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('amit_gaurav@zohomail.com',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('https://amitgaurav.online/exlog/',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Version 1.0.1', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('© 2026 ExLog. All rights reserved.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _Card({required this.icon, required this.iconColor, required this.title, required this.child});

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

class _FeatureItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _FeatureItem({required this.title, required this.description, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
