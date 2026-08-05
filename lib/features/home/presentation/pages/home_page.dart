import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../more/presentation/bloc/user_profile_bloc.dart';
import '../../../more/presentation/pages/more_page.dart';
import '../../../reminders/presentation/bloc/reminder_bloc.dart';
import '../../../reminders/presentation/pages/reminders_page.dart';
import '../../../transactions/domain/repositories/pending_sms_repository.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/pages/transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _smsPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Android SMS auto-detect: process any newly-arrived inbox entries on
    // cold start, whenever the app is foregrounded, and periodically while
    // it stays open — processInbox() only picks up SMS that arrived since
    // the last call, so without polling, an SMS received during an
    // already-open session would sit unprocessed until the next
    // background/foreground cycle.
    _processInbox();
    _startSmsPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processInbox();
      _startSmsPolling();
    } else {
      _smsPollTimer?.cancel();
    }
  }

  void _startSmsPolling() {
    _smsPollTimer?.cancel();
    _smsPollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _processInbox());
  }

  void _processInbox() {
    sl<PendingSmsRepository>().processInbox().catchError((_) {});
  }

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: AppStrings.dashboard,
      icon: Icons.bar_chart_rounded,
      activeIcon: Icons.bar_chart_rounded,
    ),
    _NavItem(
      label: AppStrings.transactions,
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
    ),
    _NavItem(
      label: AppStrings.categories,
      icon: Icons.label_outline_rounded,
      activeIcon: Icons.label_rounded,
    ),
    _NavItem(
      label: AppStrings.reminders,
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
    _NavItem(
      label: AppStrings.more,
      icon: Icons.menu_rounded,
      activeIcon: Icons.menu_rounded,
    ),
  ];

  final List<Widget> _pages = const [
    DashboardPage(),
    TransactionsPage(),
    CategoriesPage(),
    RemindersPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(create: (_) => sl<DashboardBloc>()),
        BlocProvider<CategoryBloc>(create: (_) => sl<CategoryBloc>()),
        BlocProvider<TransactionBloc>(create: (_) => sl<TransactionBloc>()),
        BlocProvider<ReminderBloc>(create: (_) => sl<ReminderBloc>()),
        BlocProvider<UserProfileBloc>(create: (_) => sl<UserProfileBloc>()),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
