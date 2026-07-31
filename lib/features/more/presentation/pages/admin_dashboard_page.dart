import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/app_config_service.dart';
import '../../domain/entities/admin_stats.dart';
import '../../domain/entities/app_rating.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>()..add(const AdminLoadRequested()),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listenWhen: (prev, cur) =>
            (cur.error != null && cur.error != prev.error) ||
            (cur.successMessage != null && cur.successMessage != prev.successMessage),
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == AdminStatus.loading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<AdminBloc>().add(const AdminLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _StatisticsSection(stats: state.stats),
                const SizedBox(height: 20),
                const _AppConfigSection(),
                const SizedBox(height: 20),
                _RatingsSection(ratingStats: state.ratingStats, recentRatings: state.recentRatings),
                const SizedBox(height: 20),
                _UsersSection(users: state.filteredUsers, totalCount: state.users.length),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  final AdminStats stats;
  const _StatisticsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Total Users', '${stats.totalUsers}', Icons.people_alt, AppColors.primary),
      ('Active', '${stats.activeUsers}', Icons.check_circle, AppColors.income),
      ('Premium', '${stats.premiumUsers}', Icons.workspace_premium, Color(0xFF5856D6)),
      ('Free', '${stats.freeUsers}', Icons.star_border, Color(0xFFFF9500)),
      ('Lifetime', '${stats.lifetimeUsers}', Icons.all_inclusive, Color(0xFFFFCC00)),
      ('Conversion', '${stats.conversionRate.toStringAsFixed(1)}%', Icons.trending_up, Color(0xFF5856D6)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statistics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            for (final c in cards)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(c.$3, color: c.$4),
                    const Spacer(),
                    Text(c.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(c.$1, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Lets an admin flip the app-wide "free for everyone" flag back off,
/// restoring the original Upgrade-to-Premium prompts and free-tier limit
/// banners for every user — without a new app release (see
/// AppConfigService / app_config/global in Firestore).
class _AppConfigSection extends StatelessWidget {
  const _AppConfigSection();

  Future<void> _confirmToggle(BuildContext context, bool newValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Change'),
        content: Text(
          newValue
              ? 'Make ExLog free for everyone? This hides all Upgrade-to-Premium prompts and limits app-wide.'
              : 'Restore premium restrictions for all free-tier users? This brings back Upgrade-to-Premium prompts and limits app-wide.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await sl<AppConfigService>().setFreeForAll(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('App Configuration', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: ValueListenableBuilder<bool>(
            valueListenable: sl<AppConfigService>().freeForAll,
            builder: (context, freeForAll, _) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Free for everyone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                'When on, all users get full access with no Upgrade-to-Premium prompts.',
                style: TextStyle(fontSize: 12),
              ),
              value: freeForAll,
              onChanged: (v) => _confirmToggle(context, v),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingsSection extends StatelessWidget {
  final RatingStatistics ratingStats;
  final List<AppRating> recentRatings;
  const _RatingsSection({required this.ratingStats, required this.recentRatings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Color(0xFFFFCC00)),
            const SizedBox(width: 8),
            const Text('App Ratings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${ratingStats.totalRatings} ratings', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Text(ratingStats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < ratingStats.averageRating.round() ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFCC00),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (final star in [5, 4, 3, 2, 1])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text('$star★', style: const TextStyle(fontSize: 12))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratingStats.percentFor(star) / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.divider,
                            color: const Color(0xFFFFCC00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 60,
                          child: Text('${ratingStats.percentFor(star).toStringAsFixed(0)}% (${ratingStats.countFor(star)})',
                              textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (recentRatings.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent Ratings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (final rating in recentRatings) _RecentRatingRow(rating: rating),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RecentRatingRow extends StatelessWidget {
  final AppRating rating;
  const _RecentRatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.userName.isEmpty ? 'Anonymous' : rating.userName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(rating.userEmail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(i < rating.rating ? Icons.star : Icons.star_border, color: const Color(0xFFFFCC00), size: 12),
                ),
              ),
            ],
          ),
          if (rating.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(rating.comment, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}

class _UsersSection extends StatefulWidget {
  final List<AdminUserSummary> users;
  final int totalCount;
  const _UsersSection({required this.users, required this.totalCount});

  @override
  State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Users', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${widget.users.length} users', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          onChanged: (v) => context.read<AdminBloc>().add(AdminUserSearchChanged(v)),
          decoration: InputDecoration(
            hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.users.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No users found', style: TextStyle(color: AppColors.textSecondary))),
          )
        else
          for (final user in widget.users) _UserRow(user: user),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final AdminUserSummary user;
  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AdminBloc>(),
                child: UserDetailsSheet(user: user),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.isPremium ? const Color(0xFF5856D6).withValues(alpha: 0.2) : AppColors.backgroundGray,
                  child: Text((user.displayName?.isNotEmpty ?? false) ? user.displayName![0].toUpperCase() : '?',
                      style: TextStyle(color: user.isPremium ? const Color(0xFF5856D6) : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      if (user.email != null)
                        Text(user.email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (user.isActive ? AppColors.income : AppColors.expense).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(user.statusBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
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

enum _AdminAction { toggleActive, grantPremium, revokePremium }

class UserDetailsSheet extends StatelessWidget {
  final AdminUserSummary user;
  const UserDetailsSheet({super.key, required this.user});

  void _confirmAction(BuildContext context, _AdminAction action, AdminUserSummary current) {
    final message = switch (action) {
      _AdminAction.toggleActive => current.isActive ? 'Deactivate this user?' : 'Activate this user?',
      _AdminAction.grantPremium => 'Grant lifetime premium to this user?',
      _AdminAction.revokePremium => 'Revoke premium access from this user?',
    };
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              switch (action) {
                case _AdminAction.toggleActive:
                  context
                      .read<AdminBloc>()
                      .add(AdminToggleUserActiveRequested(uid: current.uid, isActive: !current.isActive));
                  break;
                case _AdminAction.grantPremium:
                  context.read<AdminBloc>().add(AdminSetPremiumTierRequested(uid: current.uid, tier: PremiumTier.lifetime));
                  break;
                case _AdminAction.revokePremium:
                  context.read<AdminBloc>().add(AdminSetPremiumTierRequested(uid: current.uid, tier: PremiumTier.free));
                  break;
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('User Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          final current = state.users.firstWhere((u) => u.uid == user.uid, orElse: () => user);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _InfoRow('Email', current.email ?? 'N/A'),
                    _InfoRow('Display Name', current.displayName ?? 'N/A'),
                    _InfoRow('Status', current.isActive ? 'Active' : 'Inactive'),
                    _InfoRow('Created', DateFormat('d MMM yyyy, h:mm a').format(current.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subscription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _InfoRow('Tier', current.premiumTier.displayName),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Admin Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAction(context, _AdminAction.toggleActive, current),
                  icon: Icon(current.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline),
                  label: Text(current.isActive ? 'Deactivate User' : 'Activate User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: current.isActive ? const Color(0xFFFF9500) : AppColors.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (current.premiumTier == PremiumTier.free)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAction(context, _AdminAction.grantPremium, current),
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Grant Lifetime Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5856D6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )
              else if (current.premiumTier != PremiumTier.admin)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmAction(context, _AdminAction.revokePremium, current),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Revoke Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          );
        },
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
