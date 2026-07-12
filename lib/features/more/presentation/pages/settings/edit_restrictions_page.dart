import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../domain/services/edit_restriction_checker.dart';

class EditRestrictionsPage extends StatefulWidget {
  const EditRestrictionsPage({super.key});

  @override
  State<EditRestrictionsPage> createState() => _EditRestrictionsPageState();
}

class _EditRestrictionsPageState extends State<EditRestrictionsPage> {
  late EditRestrictionPeriod _selected;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _selected = sl<EditRestrictionChecker>().currentRestriction;
  }

  Future<void> _select(EditRestrictionPeriod period) async {
    await sl<EditRestrictionChecker>().setRestriction(period);
    setState(() {
      _selected = period;
      _showSaved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Edit Restrictions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_showSaved)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.income, size: 18),
                  SizedBox(width: 8),
                  Text('Setting saved successfully', style: TextStyle(color: AppColors.income, fontSize: 13)),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('SELECT RESTRICTION PERIOD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                for (var i = 0; i < EditRestrictionPeriod.values.length; i++) ...[
                  ListTile(
                    onTap: () => _select(EditRestrictionPeriod.values[i]),
                    title: Text(EditRestrictionPeriod.values[i].displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    subtitle: Text(EditRestrictionPeriod.values[i].description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: _selected == EditRestrictionPeriod.values[i]
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                  ),
                  if (i < EditRestrictionPeriod.values.length - 1)
                    const Divider(height: 1, indent: 16, color: AppColors.divider),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 4, right: 4),
            child: Text(
              'Transactions can only be edited if they were created within the selected time period. Choose '
              '"No Restrictions" to allow editing all transactions anytime.\n\nCurrent selection is automatically saved.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This setting helps prevent accidental changes to older transactions while allowing recent '
                    'ones to be corrected. Select "No Restrictions" if you prefer full editing freedom.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
