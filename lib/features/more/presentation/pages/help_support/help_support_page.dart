import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../bloc/rating_bloc.dart';
import 'about_us_page.dart';
import 'faqs_page.dart';
import 'how_it_works_page.dart';
import 'rate_us_page.dart';

const String kSupportEmail = 'amit_gaurav@zohomail.com';
const String kWebsiteUrl = 'https://amitgaurav.online/exlog/';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionHeader('Help & Support'),
          _Row(
            icon: Icons.info_outline,
            iconColor: AppColors.primary,
            title: 'About Us',
            subtitle: "Learn about ExLog's vision and mission",
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutUsPage())),
          ),
          _Row(
            icon: Icons.lightbulb_outline,
            iconColor: const Color(0xFFFF9500),
            title: 'How does ExLog work?',
            subtitle: "Understand the app's features and workflow",
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HowItWorksPage())),
          ),
          _Row(
            icon: Icons.help_outline,
            iconColor: AppColors.income,
            title: 'FAQs',
            subtitle: 'Frequently asked questions',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FAQsPage())),
          ),
          _Row(
            icon: Icons.star_outline,
            iconColor: const Color(0xFFFFCC00),
            title: 'Rate Us',
            subtitle: 'Share your feedback and rating',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => sl<RatingBloc>(),
                  child: const RateUsPage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Contact Us'),
          _Row(
            icon: Icons.mail_outline,
            iconColor: AppColors.primary,
            title: 'Email Support',
            onTap: () => launchUrl(Uri.parse('mailto:$kSupportEmail')),
          ),
          _Row(
            icon: Icons.public,
            iconColor: AppColors.primary,
            title: 'Visit Website',
            onTap: () => launchUrl(Uri.parse(kWebsiteUrl), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
