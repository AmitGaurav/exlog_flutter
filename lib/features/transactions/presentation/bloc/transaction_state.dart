import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

enum TransactionStatus { initial, loading, success, failure }

class TransactionState extends Equatable {
  final TransactionStatus status;
  final List<Transaction> transactions;
  final TransactionFilter filter;
  final String? error;

  const TransactionState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.filter = const TransactionFilter(),
    this.error,
  });

  List<Transaction> get filteredTransactions {
    final list = transactions.where(filter.matches).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Groups [filteredTransactions] by day, preserving descending order,
  /// keyed by a display label ("Today", "Yesterday", or a formatted date).
  List<MapEntry<String, List<Transaction>>> get groupedByDay {
    final grouped = <String, List<Transaction>>{};
    for (final t in filteredTransactions) {
      (grouped[_dayLabel(t.timestamp)] ??= []).add(t);
    }
    return grouped.entries.toList();
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMMM yyyy').format(date);
  }

  TransactionState copyWith({
    TransactionStatus? status,
    List<Transaction>? transactions,
    TransactionFilter? filter,
    String? error,
    bool clearError = false,
  }) =>
      TransactionState(
        status: status ?? this.status,
        transactions: transactions ?? this.transactions,
        filter: filter ?? this.filter,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, transactions, filter, error];
}
