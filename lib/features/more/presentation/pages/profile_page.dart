import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/app_config_service.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/user_profile_bloc.dart';
import '../bloc/user_profile_event.dart';
import '../bloc/user_profile_state.dart';
import '../widgets/free_tier_upgrade_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          if (state.status == UserProfileStatus.loading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = state.profile;
          if (profile == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
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
                        profile.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(profile.displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(profile.email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ValueListenableBuilder<bool>(
                valueListenable: sl<AppConfigService>().freeForAll,
                builder: (context, freeForAll, _) => _CardSection(
                  title: 'Subscription Status',
                  child: profile.premiumTier.isPremium
                      ? _PremiumActiveContent(profile: profile)
                      : (freeForAll ? const _FreeAppContent() : _FreeTierContent()),
                ),
              ),
              const SizedBox(height: 16),
              _CardSection(
                title: 'Account Information',
                child: Column(
                  children: [
                    _InfoRow('User ID', profile.uid),
                    const Divider(height: 1, indent: 16, color: AppColors.divider),
                    _InfoRow('Email', profile.email),
                    const Divider(height: 1, indent: 16, color: AppColors.divider),
                    _InfoRow('Display Name', profile.displayName),
                    const Divider(height: 1, indent: 16, color: AppColors.divider),
                    _InfoRow('Account Created', DateFormat('d MMM yyyy').format(profile.createdAt)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumActiveContent extends StatelessWidget {
  final UserProfile profile;
  const _PremiumActiveContent({required this.profile});

  static const _benefits = [
    ('Unlimited SMS imports', Icons.mail_outline),
    ('Unlimited exports', Icons.ios_share),
    ('Unlimited reminders', Icons.notifications_outlined),
    ('Unlimited categories', Icons.folder_outlined),
    ('AI-powered SMS parsing', Icons.auto_awesome),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                child: const Icon(Icons.workspace_premium, color: Color(0xFFFFCC00), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(profile.premiumTier.displayName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle, color: AppColors.income, size: 18),
                      ],
                    ),
                    const Text('All premium features unlocked',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          const Text('Your Benefits',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          for (final b in _benefits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(b.$2, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(b.$1, style: const TextStyle(fontSize: 15))),
                  const Icon(Icons.check, color: AppColors.income, size: 16),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchases are up to date.')),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Restore Purchases'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeAppContent extends StatelessWidget {
  const _FreeAppContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.favorite_border, color: Color(0xFFFFCC00), size: 32),
          SizedBox(width: 14),
          Expanded(
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
    );
  }
}

class _FreeTierContent extends StatelessWidget {
  static const _limits = [
    ('10 SMS imports/month', Icons.mail_outline),
    ('5 exports/month', Icons.ios_share),
    ('3 active reminders', Icons.notifications_outlined),
    ('5 custom categories', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: AppColors.backgroundGray, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Free Tier', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text('Limited features available',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          const Text('Current Limits',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          for (final l in _limits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(l.$2, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.$1, style: const TextStyle(fontSize: 15))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const FreeTierUpgradeSheet(),
                );
                // Refresh on close (harmless if no purchase happened) so a
                // successful purchase's server-written premiumTier shows up
                // without requiring an app restart.
                if (context.mounted) {
                  context.read<UserProfileBloc>().add(const UserProfileLoadRequested());
                }
              },
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: const Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1, color: AppColors.divider),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
