import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'sms_auto_detect_enabled';

/// Android-only (no iOS analog): toggles the SMS_RECEIVED listener that
/// auto-detects bank SMS in the background for approve/reject review on the
/// Transactions page. The native `SmsReceiver` reads this same
/// SharedPreferences flag directly (key `flutter.sms_auto_detect_enabled`)
/// so toggling it off fully stops processing without needing to
/// register/unregister the manifest receiver dynamically.
class SmsAutoDetectRow extends StatefulWidget {
  const SmsAutoDetectRow({super.key});

  @override
  State<SmsAutoDetectRow> createState() => _SmsAutoDetectRowState();
}

class _SmsAutoDetectRowState extends State<SmsAutoDetectRow> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = sl<SharedPreferences>();
    setState(() {
      _enabled = prefs.getBool(_prefsKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    final prefs = sl<SharedPreferences>();
    if (!value) {
      await prefs.setBool(_prefsKey, false);
      setState(() => _enabled = false);
      return;
    }

    final status = await Permission.sms.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission is required to auto-detect transactions.'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
      return;
    }

    await prefs.setBool(_prefsKey, true);
    setState(() => _enabled = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text('Auto-detect from SMS'),
        subtitle: const Text(
          'Scan incoming bank SMS in the background and queue matches for your approval',
          style: TextStyle(fontSize: 12),
        ),
        value: _enabled,
        onChanged: _loading ? null : _onChanged,
      ),
    );
  }
}
