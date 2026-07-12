import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../categories/domain/entities/category.dart';

enum TransactionType {
  expense,
  credit,
  cashWithdrawal,
  selfTransfer;

  String get rawValue {
    switch (this) {
      case expense:
        return 'expense';
      case credit:
        return 'credit';
      case cashWithdrawal:
        return 'cash_withdrawal';
      case selfTransfer:
        return 'self_transfer';
    }
  }

  String get displayName {
    switch (this) {
      case expense:
        return 'Expense';
      case credit:
        return 'Credit';
      case cashWithdrawal:
        return 'Cash Withdrawal';
      case selfTransfer:
        return 'Self Transfer';
    }
  }

  static TransactionType fromString(String value) => TransactionType.values.firstWhere(
        (e) => e.rawValue == value,
        orElse: () => TransactionType.expense,
      );
}

class Transaction extends Equatable {
  final String? id;
  final double amount;
  final String payee;
  final String? categoryId;
  final String? categoryName;
  final BucketType? bucket;
  final DateTime timestamp;
  final TransactionType type;
  final String? notes;
  final bool isManual;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bankName;
  final String? accountNumber;
  final String? transactionReference;
  final bool? parsedByAI;
  final String? importSource;
  final String? smsRaw;

  const Transaction({
    this.id,
    required this.amount,
    required this.payee,
    this.categoryId,
    this.categoryName,
    this.bucket,
    required this.timestamp,
    required this.type,
    this.notes,
    this.isManual = true,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.bankName,
    this.accountNumber,
    this.transactionReference,
    this.parsedByAI,
    this.importSource,
    this.smsRaw,
  });

  factory Transaction.create({
    required double amount,
    required String payee,
    String? categoryId,
    String? categoryName,
    BucketType? bucket,
    required DateTime timestamp,
    required TransactionType type,
    String? notes,
    bool isManual = true,
    required String userId,
    String? bankName,
    String? accountNumber,
    String? transactionReference,
    bool? parsedByAI,
    String? importSource,
    String? smsRaw,
  }) {
    final now = DateTime.now();
    return Transaction(
      amount: amount,
      payee: payee,
      categoryId: categoryId,
      categoryName: categoryName,
      bucket: bucket,
      timestamp: timestamp,
      type: type,
      notes: notes,
      isManual: isManual,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      bankName: bankName,
      accountNumber: accountNumber,
      transactionReference: transactionReference,
      parsedByAI: parsedByAI,
      importSource: importSource,
      smsRaw: smsRaw,
    );
  }

  factory Transaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Transaction(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      payee: data['payee'] as String? ?? '',
      categoryId: data['categoryId'] as String?,
      categoryName: data['categoryName'] as String?,
      bucket: data['bucket'] != null ? BucketType.fromString(data['bucket'] as String) : null,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: TransactionType.fromString(data['type'] as String? ?? 'expense'),
      notes: data['notes'] as String?,
      isManual: data['isManual'] as bool? ?? true,
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bankName: data['bankName'] as String?,
      accountNumber: data['accountNumber'] as String?,
      transactionReference: data['transactionReference'] as String?,
      parsedByAI: data['parsedByAI'] as bool?,
      importSource: data['importSource'] as String?,
      smsRaw: data['smsRaw'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'amount': amount,
        'payee': payee,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'bucket': bucket?.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'type': type.rawValue,
        'notes': notes,
        'isManual': isManual,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'bankName': bankName,
        'accountNumber': accountNumber,
        'transactionReference': transactionReference,
        'parsedByAI': parsedByAI,
        'importSource': importSource,
        'smsRaw': smsRaw,
      };

  Transaction copyWith({
    String? id,
    double? amount,
    String? payee,
    String? categoryId,
    String? categoryName,
    BucketType? bucket,
    DateTime? timestamp,
    TransactionType? type,
    String? notes,
    bool? isManual,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bankName,
    String? accountNumber,
    String? transactionReference,
    bool? parsedByAI,
    String? importSource,
    String? smsRaw,
  }) =>
      Transaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        payee: payee ?? this.payee,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        bucket: bucket ?? this.bucket,
        timestamp: timestamp ?? this.timestamp,
        type: type ?? this.type,
        notes: notes ?? this.notes,
        isManual: isManual ?? this.isManual,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        bankName: bankName ?? this.bankName,
        accountNumber: accountNumber ?? this.accountNumber,
        transactionReference: transactionReference ?? this.transactionReference,
        parsedByAI: parsedByAI ?? this.parsedByAI,
        importSource: importSource ?? this.importSource,
        smsRaw: smsRaw ?? this.smsRaw,
      );

  @override
  List<Object?> get props => [
        id, amount, payee, categoryId, categoryName, bucket, timestamp, type,
        notes, isManual, userId, createdAt, updatedAt, bankName, accountNumber,
        transactionReference, parsedByAI, importSource, smsRaw,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtering
// ─────────────────────────────────────────────────────────────────────────────

enum DateRangeOption {
  today,
  thisWeek,
  thisMonth,
  last3Months,
  last6Months,
  thisYear,
  specificYear,
  customRange,
  all;

  String get label {
    switch (this) {
      case today:
        return 'Today';
      case thisWeek:
        return 'This Week';
      case thisMonth:
        return 'This Month';
      case last3Months:
        return 'Last 3 Months';
      case last6Months:
        return 'Last 6 Months';
      case thisYear:
        return 'This Year';
      case specificYear:
        return 'Year';
      case customRange:
        return 'Custom Range';
      case all:
        return 'All Time';
    }
  }

  bool contains(
    DateTime date, {
    int? selectedYear,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    switch (this) {
      case today:
        return _isSameDay(date, now);
      case thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return !date.isBefore(startOfDay) && date.isBefore(startOfDay.add(const Duration(days: 7)));
      case thisMonth:
        return date.year == now.year && date.month == now.month;
      case last3Months:
        final cutoff = DateTime(now.year, now.month - 2, 1);
        return !date.isBefore(cutoff);
      case last6Months:
        final cutoff = DateTime(now.year, now.month - 5, 1);
        return !date.isBefore(cutoff);
      case thisYear:
        return date.year == now.year;
      case specificYear:
        return selectedYear != null && date.year == selectedYear;
      case customRange:
        if (customStart == null || customEnd == null) return true;
        final startOfDay = DateTime(customStart.year, customStart.month, customStart.day);
        final endOfDay = DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59, 999);
        return !date.isBefore(startOfDay) && !date.isAfter(endOfDay);
      case all:
        return true;
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class TransactionFilter extends Equatable {
  final DateRangeOption dateRange;
  final int? selectedYear;
  final DateTime? customStart;
  final DateTime? customEnd;
  final TransactionType? type;
  final String? categoryId;
  final String searchText;

  const TransactionFilter({
    this.dateRange = DateRangeOption.thisMonth,
    this.selectedYear,
    this.customStart,
    this.customEnd,
    this.type,
    this.categoryId,
    this.searchText = '',
  });

  int get activeFilterCount {
    var count = 0;
    if (dateRange != DateRangeOption.thisMonth) count++;
    if (type != null) count++;
    if (categoryId != null) count++;
    return count;
  }

  bool matches(Transaction transaction) {
    if (!dateRange.contains(
      transaction.timestamp,
      selectedYear: selectedYear,
      customStart: customStart,
      customEnd: customEnd,
    )) {
      return false;
    }
    if (type != null && transaction.type != type) return false;
    if (categoryId != null && transaction.categoryId != categoryId) return false;
    if (searchText.trim().isNotEmpty) {
      final needle = searchText.trim().toLowerCase();
      final haystack = [
        transaction.payee,
        transaction.categoryName ?? '',
        transaction.notes ?? '',
      ].join(' ').toLowerCase();
      if (!haystack.contains(needle)) return false;
    }
    return true;
  }

  TransactionFilter copyWith({
    DateRangeOption? dateRange,
    int? selectedYear,
    DateTime? customStart,
    DateTime? customEnd,
    TransactionType? type,
    String? categoryId,
    String? searchText,
    bool clearSelectedYear = false,
    bool clearCustomRange = false,
    bool clearType = false,
    bool clearCategoryId = false,
  }) =>
      TransactionFilter(
        dateRange: dateRange ?? this.dateRange,
        selectedYear: clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
        customStart: clearCustomRange ? null : (customStart ?? this.customStart),
        customEnd: clearCustomRange ? null : (customEnd ?? this.customEnd),
        type: clearType ? null : (type ?? this.type),
        categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
        searchText: searchText ?? this.searchText,
      );

  @override
  List<Object?> get props => [
        dateRange, selectedYear, customStart, customEnd, type, categoryId, searchText,
      ];
}
