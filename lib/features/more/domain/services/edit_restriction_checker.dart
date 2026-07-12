import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../transactions/domain/entities/transaction.dart';

enum EditRestrictionPeriod {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  static EditRestrictionPeriod fromString(String? value) => EditRestrictionPeriod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EditRestrictionPeriod.monthly,
      );

  String get displayName {
    switch (this) {
      case EditRestrictionPeriod.none:
        return 'No Restrictions';
      case EditRestrictionPeriod.daily:
        return 'Daily';
      case EditRestrictionPeriod.weekly:
        return 'Weekly';
      case EditRestrictionPeriod.monthly:
        return 'Monthly';
      case EditRestrictionPeriod.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case EditRestrictionPeriod.none:
        return 'All transactions can be edited and deleted anytime';
      case EditRestrictionPeriod.daily:
        return 'Transactions can be edited if created today';
      case EditRestrictionPeriod.weekly:
        return 'Transactions can be edited if created this week';
      case EditRestrictionPeriod.monthly:
        return 'Transactions can be edited if created this month';
      case EditRestrictionPeriod.yearly:
        return 'Transactions can be edited if created this year';
    }
  }
}

/// Ported 1:1 from iOS's `EditRestrictionManager` — local-only preference
/// (`SharedPreferences` here, `UserDefaults` on iOS), no Firestore field.
class EditRestrictionChecker {
  static const _key = 'transaction_edit_restriction';

  final SharedPreferences _prefs;

  EditRestrictionChecker(this._prefs);

  EditRestrictionPeriod get currentRestriction =>
      EditRestrictionPeriod.fromString(_prefs.getString(_key));

  Future<void> setRestriction(EditRestrictionPeriod period) =>
      _prefs.setString(_key, period.name);

  bool isTransactionEditable(Transaction transaction) {
    final period = currentRestriction;
    if (period == EditRestrictionPeriod.none) return true;

    final created = transaction.createdAt;
    final now = DateTime.now();

    switch (period) {
      case EditRestrictionPeriod.none:
        return true;
      case EditRestrictionPeriod.daily:
        return created.year == now.year && created.month == now.month && created.day == now.day;
      case EditRestrictionPeriod.weekly:
        return _weekOfYear(created) == _weekOfYear(now) && created.year == now.year;
      case EditRestrictionPeriod.monthly:
        return created.year == now.year && created.month == now.month;
      case EditRestrictionPeriod.yearly:
        return created.year == now.year;
    }
  }

  String getRestrictionMessage(Transaction transaction) {
    final createdDateString = DateFormat('MMM d, yyyy h:mm a').format(transaction.createdAt);
    switch (currentRestriction) {
      case EditRestrictionPeriod.none:
        return 'This transaction can be freely edited and deleted (No Restrictions)';
      case EditRestrictionPeriod.daily:
        return 'This transaction was created on $createdDateString and can no longer be edited or deleted (Daily restriction)';
      case EditRestrictionPeriod.weekly:
        return 'This transaction was created on $createdDateString and can no longer be edited or deleted (Weekly restriction)';
      case EditRestrictionPeriod.monthly:
        return 'This transaction was created on $createdDateString and can no longer be edited or deleted (Monthly restriction)';
      case EditRestrictionPeriod.yearly:
        return 'This transaction was created on $createdDateString and can no longer be edited or deleted (Yearly restriction)';
    }
  }

  int _weekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(startOfYear).inDays;
    return ((days + startOfYear.weekday - 1) / 7).floor() + 1;
  }
}
