import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/app_config_service.dart';
import '../../../../auth/domain/repositories/auth_repository.dart';
import '../../../../categories/presentation/bloc/category_bloc.dart';
import '../../../domain/entities/user_profile.dart';
import '../../bloc/payee_mapping_bloc.dart';
import '../../bloc/transaction_type_bloc.dart';
import '../../bloc/user_profile_bloc.dart';
import '../../bloc/user_profile_event.dart';
import '../../bloc/user_profile_state.dart';
import '../../widgets/free_tier_upgrade_sheet.dart';
import '../admin_dashboard_page.dart';
import '../more_page.dart' show kPrivacyPolicyUrl, kTermsOfServiceUrl;
import 'ai_sms_parser_page.dart';
import 'change_password_page.dart';
import 'currency_page.dart';
import 'edit_restrictions_page.dart';
import 'import_historical_data_page.dart';
import 'payee_mappings_page.dart';
import 'transaction_types_page.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          final profile = state.profile;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SectionHeader('Subscription'),
              _SubscriptionRow(profile: profile),
              if (state.isAdmin) ...[
                const SizedBox(height: 20),
                _SectionHeader('Super Admin'),
                _Row(
                  icon: Icons.shield_outlined,
                  iconColor: AppColors.expense,
                  title: 'Admin Dashboard',
                  subtitle: 'Manage users and view statistics',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _SectionHeader('Data Management'),
              _Row(
                icon: Icons.people_alt_outlined,
                iconColor: AppColors.primary,
                title: 'Payee Mappings',
                subtitle: 'Auto-categorize by payee name',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => sl<PayeeMappingBloc>()),
                        BlocProvider.value(value: context.read<CategoryBloc>()),
                      ],
                      child: const PayeeMappingsPage(),
                    ),
                  ),
                ),
              ),
              _Row(
                icon: Icons.grid_view_outlined,
                iconColor: const Color(0xFF5856D6),
                title: 'Transaction Types',
                subtitle: 'Manage expense, credit & custom types',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => sl<TransactionTypeBloc>(),
                      child: const TransactionTypesPage(),
                    ),
                  ),
                ),
              ),
              _Row(
                icon: Icons.file_download_outlined,
                iconColor: AppColors.income,
                title: 'Import Historical Data',
                subtitle: 'Import from CSV file',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportHistoricalDataPage()),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('SMS Import'),
              _Row(
                icon: Icons.psychology_outlined,
                iconColor: const Color(0xFFFF9500),
                title: 'AI SMS Parser',
                subtitle: 'Configure AI-powered SMS parsing',
                trailing: profile != null && profile.aiParserConfig.isEnabled && profile.aiParserConfig.apiKeyObfuscated != null
                    ? const Icon(Icons.check_circle, color: AppColors.income, size: 18)
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<UserProfileBloc>(),
                      child: const AISmsParserPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('Preferences'),
              _Row(
                icon: Icons.attach_money,
                iconColor: AppColors.income,
                title: 'Currency',
                subtitle: 'Display currency for amounts',
                trailingText: profile?.preferredCurrency,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<UserProfileBloc>(),
                      child: const CurrencyPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('Transaction Editing'),
              _Row(
                icon: Icons.lock_clock_outlined,
                iconColor: const Color(0xFFFF9500),
                title: 'Edit Restrictions',
                subtitle: 'Control when transactions can be edited',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditRestrictionsPage()),
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader('About'),
              _Row(
                icon: Icons.info_outline,
                iconColor: AppColors.textSecondary,
                title: 'Version',
                trailingText: '1.0.1',
                onTap: null,
              ),
              const SizedBox(height: 20),
              _SectionHeader('Legal'),
              _Row(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.primary,
                title: 'Privacy Policy',
                onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
              ),
              _Row(
                icon: Icons.description_outlined,
                iconColor: AppColors.primary,
                title: 'Terms of Service',
                onTap: () => launchUrl(Uri.parse(kTermsOfServiceUrl), mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 20),
              _SectionHeader('Account Security'),
              _Row(
                icon: Icons.password_outlined,
                iconColor: AppColors.primary,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _confirmDeleteAccount(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'Delete Account',
                          style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'This will permanently delete your account and all associated data. This action cannot be undone.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'Are you sure you want to delete your account? All your transactions, categories, reminders, and settings will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _confirmDeleteAccountFinal(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccountFinal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
            'This is irreversible. Your account and ALL data will be permanently deleted. Are you absolutely sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              DeleteAccountFlow.execute(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );
  }
}

/// Calls `AuthRepository.deleteAccount()` (the `deleteUserAccount` Cloud
/// Function, same one iOS already uses) then signs out. The auth stream
/// picks up the sign-out automatically and go_router redirects to /login —
/// no manual navigation needed here.
class DeleteAccountFlow {
  static Future<void> execute(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await sl<AuthRepository>().deleteAccount();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Deletion Failed'),
          content: Text('$e'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _SubscriptionRow extends StatelessWidget {
  final UserProfile? profile;
  const _SubscriptionRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isPremium = profile?.premiumTier.isPremium ?? false;
    return ValueListenableBuilder<bool>(
      valueListenable: sl<AppConfigService>().freeForAll,
      builder: (context, freeForAll, _) {
        final isFreeApp = !isPremium && freeForAll;
        final tappable = !isPremium && !freeForAll;
        return Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: !tappable
                  ? null
                  : () async {
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isFreeApp ? Icons.favorite_border : Icons.workspace_premium,
                      color: const Color(0xFFFFCC00),
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium
                                ? '${profile!.premiumTier.displayName} Active'
                                : (isFreeApp ? 'ExLog is Free' : 'Upgrade to Premium'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            isPremium
                                ? 'Full access to all features'
                                : (isFreeApp
                                    ? 'No subscriptions, no limits'
                                    : 'Unlock unlimited imports, exports & more'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (tappable) const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    if (isPremium) const Icon(Icons.check_circle, color: AppColors.income),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
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
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailing,
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
                      Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(6)),
                      child: Text(trailingText!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ),
                if (trailing != null) Padding(padding: const EdgeInsets.only(right: 6), child: trailing),
                if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
