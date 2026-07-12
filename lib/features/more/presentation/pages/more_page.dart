import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../bloc/user_profile_bloc.dart';
import '../bloc/user_profile_event.dart';
import '../bloc/user_profile_state.dart';
import 'admin_dashboard_page.dart';
import 'help_support/help_support_page.dart';
import 'profile_page.dart';
import 'settings/app_settings_page.dart';

const String kPrivacyPolicyUrl = 'https://amitgaurav.online/exlog/privacy-policy';
const String kTermsOfServiceUrl = 'https://amitgaurav.online/exlog/terms-of-service';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(const UserProfileLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          return ListView(
            children: [
              const SizedBox(height: 8),
              _SectionHeader('Profile'),
              _ProfileRow(state: state),
              if (state.isAdmin) ...[
                const SizedBox(height: 20),
                _SectionHeader('Super Admin'),
                _MoreRow(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.expense,
                  title: 'Admin Dashboard',
                  subtitle: 'Manage users and view analytics',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _SectionHeader('Support'),
              _MoreRow(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Help & Support',
                subtitle: 'Get answers to your questions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportPage()),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('Configuration'),
              _MoreRow(
                icon: Icons.settings_outlined,
                iconColor: AppColors.textSecondary,
                title: 'App Settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<UserProfileBloc>()),
                        BlocProvider.value(value: context.read<CategoryBloc>()),
                      ],
                      child: const AppSettingsPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('Legal'),
              _MoreRow(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.primary,
                title: 'Privacy Policy',
                onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
              ),
              _MoreRow(
                icon: Icons.description_outlined,
                iconColor: AppColors.primary,
                title: 'Terms of Service',
                onTap: () => launchUrl(Uri.parse(kTermsOfServiceUrl), mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppColors.backgroundGray,
                  title: const Center(
                    child: Text(
                      'Sign Out',
                      style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
                    ),
                  ),
                  onTap: () => _confirmSignOut(context),
                ),
              ),
              const SizedBox(height: 32),
              const _AppInfoFooter(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final UserProfileState state;
  const _ProfileRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<UserProfileBloc>(),
                child: const ProfilePage(),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.avatarPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile?.initials ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'User',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MoreRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
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
                        Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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

class _AppInfoFooter extends StatelessWidget {
  const _AppInfoFooter();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 44, color: AppColors.primary),
          SizedBox(height: 10),
          Text('ExLog', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('Version 1.0.1', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          SizedBox(height: 2),
          Text('© 2026 ExLog. All rights reserved.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
