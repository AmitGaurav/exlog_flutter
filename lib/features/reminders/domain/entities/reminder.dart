import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RepeatType {
  monthly,
  quarterly,
  halfYearly,
  yearly,
  custom;

  String get rawValue {
    switch (this) {
      case monthly:
        return 'monthly';
      case quarterly:
        return 'quarterly';
      case halfYearly:
        return 'half_yearly';
      case yearly:
        return 'yearly';
      case custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case monthly:
        return 'Monthly';
      case quarterly:
        return 'Quarterly';
      case halfYearly:
        return 'Half Yearly';
      case yearly:
        return 'Yearly';
      case custom:
        return 'Custom';
    }
  }

  int get daysInterval {
    switch (this) {
      case monthly:
        return 30;
      case quarterly:
        return 90;
      case halfYearly:
        return 180;
      case yearly:
        return 365;
      case custom:
        return 0;
    }
  }

  static RepeatType fromString(String value) => RepeatType.values.firstWhere(
        (e) => e.rawValue == value,
        orElse: () => RepeatType.monthly,
      );
}

class Reminder extends Equatable {
  final String? id;
  final String title;
  final double? amount;
  final DateTime dueDate;
  final RepeatType repeatType;
  final int? customDaysInterval;
  final bool notificationEnabled;
  final int notificationDaysBefore;
  final String? categoryId;
  final String? categoryName;
  final String? notes;
  final bool isPaid;
  final DateTime? lastPaidDate;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    this.id,
    required this.title,
    this.amount,
    required this.dueDate,
    this.repeatType = RepeatType.monthly,
    this.customDaysInterval,
    this.notificationEnabled = true,
    this.notificationDaysBefore = 3,
    this.categoryId,
    this.categoryName,
    this.notes,
    this.isPaid = false,
    this.lastPaidDate,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Reminder.create({
    required String title,
    double? amount,
    required DateTime dueDate,
    RepeatType repeatType = RepeatType.monthly,
    int? customDaysInterval,
    bool notificationEnabled = true,
    int notificationDaysBefore = 3,
    String? categoryId,
    String? categoryName,
    String? notes,
    required String userId,
  }) {
    final now = DateTime.now();
    return Reminder(
      title: title,
      amount: amount,
      dueDate: dueDate,
      repeatType: repeatType,
      customDaysInterval: customDaysInterval,
      notificationEnabled: notificationEnabled,
      notificationDaysBefore: notificationDaysBefore,
      categoryId: categoryId,
      categoryName: categoryName,
      notes: notes,
      isPaid: false,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Reminder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Reminder(
      id: doc.id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repeatType: RepeatType.fromString(data['repeatType'] as String? ?? 'monthly'),
      customDaysInterval: data['customDaysInterval'] as int?,
      notificationEnabled: data['notificationEnabled'] as bool? ?? true,
      notificationDaysBefore: data['notificationDaysBefore'] as int? ?? 3,
      categoryId: data['categoryId'] as String?,
      categoryName: data['categoryName'] as String?,
      notes: data['notes'] as String?,
      isPaid: data['isPaid'] as bool? ?? false,
      lastPaidDate: (data['lastPaidDate'] as Timestamp?)?.toDate(),
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'repeatType': repeatType.rawValue,
        'customDaysInterval': customDaysInterval,
        'notificationEnabled': notificationEnabled,
        'notificationDaysBefore': notificationDaysBefore,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'notes': notes,
        'isPaid': isPaid,
        'lastPaidDate': lastPaidDate == null ? null : Timestamp.fromDate(lastPaidDate!),
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Mirrors iOS RecurringReminder.nextDueDate: while unpaid (or never paid),
  /// the due date itself is next; once paid, the next cycle is computed from
  /// lastPaidDate + the repeat interval.
  DateTime get nextDueDate {
    if (!isPaid || lastPaidDate == null) return dueDate;
    final interval = repeatType == RepeatType.custom
        ? (customDaysInterval ?? 0)
        : repeatType.daysInterval;
    return lastPaidDate!.add(Duration(days: interval));
  }

  bool get isOverdue => !isPaid && nextDueDate.isBefore(DateTime.now());

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  Reminder markedAsPaid({DateTime? date}) => copyWith(
        isPaid: true,
        lastPaidDate: date ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Matches iOS undoPayment(): only isPaid flips back — lastPaidDate is kept.
  Reminder paymentUndone() => copyWith(isPaid: false, updatedAt: DateTime.now());

  Reminder copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    RepeatType? repeatType,
    int? customDaysInterval,
    bool? notificationEnabled,
    int? notificationDaysBefore,
    String? categoryId,
    String? categoryName,
    String? notes,
    bool? isPaid,
    DateTime? lastPaidDate,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAmount = false,
    bool clearCategoryId = false,
    bool clearCategoryName = false,
    bool clearCustomDaysInterval = false,
  }) =>
      Reminder(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: clearAmount ? null : (amount ?? this.amount),
        dueDate: dueDate ?? this.dueDate,
        repeatType: repeatType ?? this.repeatType,
        customDaysInterval:
            clearCustomDaysInterval ? null : (customDaysInterval ?? this.customDaysInterval),
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        notificationDaysBefore: notificationDaysBefore ?? this.notificationDaysBefore,
        categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
        categoryName: clearCategoryName ? null : (categoryName ?? this.categoryName),
        notes: notes ?? this.notes,
        isPaid: isPaid ?? this.isPaid,
        lastPaidDate: lastPaidDate ?? this.lastPaidDate,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id, title, amount, dueDate, repeatType, customDaysInterval,
        notificationEnabled, notificationDaysBefore, categoryId, categoryName,
        notes, isPaid, lastPaidDate, userId, createdAt, updatedAt,
      ];
}
