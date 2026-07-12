import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/app_currency.dart';
import '../../bloc/user_profile_bloc.dart';
import '../../bloc/user_profile_event.dart';
import '../../bloc/user_profile_state.dart';

class CurrencyPage extends StatelessWidget {
  const CurrencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          final selected = AppCurrency.fromCode(state.profile?.preferredCurrency);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('SELECT CURRENCY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              Container(
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    for (var i = 0; i < AppCurrency.values.length; i++) ...[
                      ListTile(
                        onTap: () => context
                            .read<UserProfileBloc>()
                            .add(UserProfileCurrencyChanged(AppCurrency.values[i].code)),
                        leading: Text(AppCurrency.values[i].flag, style: const TextStyle(fontSize: 24)),
                        title: Row(
                          children: [
                            Text(AppCurrency.values[i].symbol,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Text(AppCurrency.values[i].code, style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        subtitle: Text(AppCurrency.values[i].currencyName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        trailing: selected == AppCurrency.values[i]
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : null,
                      ),
                      if (i < AppCurrency.values.length - 1) const Divider(height: 1, indent: 16, color: AppColors.divider),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, left: 4, right: 4),
                child: Text(
                  'The selected currency symbol will be displayed with all amounts across the app. This is a '
                  'display preference only and does not convert amounts.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
