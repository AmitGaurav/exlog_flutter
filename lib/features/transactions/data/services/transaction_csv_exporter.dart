import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

/// Mirrors ExLog/Managers/TransactionExportManager.swift so exported CSVs
/// are byte-for-byte compatible between the iOS and Flutter apps.
sealed class ExportTimeframe {
  const ExportTimeframe();
}

class AllTimeframe extends ExportTimeframe {
  const AllTimeframe();
}

class CurrentMonthTimeframe extends ExportTimeframe {
  const CurrentMonthTimeframe();
}

class CustomMonthTimeframe extends ExportTimeframe {
  final int year;
  final int month;
  const CustomMonthTimeframe({required this.year, required this.month});
}

class CustomYearTimeframe extends ExportTimeframe {
  final int year;
  const CustomYearTimeframe({required this.year});
}

class DateRangeTimeframe extends ExportTimeframe {
  final DateTime start;
  final DateTime end;
  const DateRangeTimeframe({required this.start, required this.end});
}

class TransactionCsvExporter {
  TransactionCsvExporter._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm:ss');
  static final _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _monthFormat = DateFormat('yyyy-MM');
  static final _monthNameFormat = DateFormat('MMMM');

  static String exportToCsv(List<Transaction> transactions, ExportTimeframe timeframe) {
    final filtered = _filter(transactions, timeframe);
    return _generateCsv(filtered);
  }

  static List<Transaction> _filter(List<Transaction> transactions, ExportTimeframe timeframe) {
    switch (timeframe) {
      case AllTimeframe():
        return transactions;
      case CurrentMonthTimeframe():
        final now = DateTime.now();
        return transactions
            .where((t) => t.timestamp.year == now.year && t.timestamp.month == now.month)
            .toList();
      case CustomMonthTimeframe(year: final year, month: final month):
        return transactions
            .where((t) => t.timestamp.year == year && t.timestamp.month == month)
            .toList();
      case CustomYearTimeframe(year: final year):
        return transactions.where((t) => t.timestamp.year == year).toList();
      case DateRangeTimeframe(start: final start, end: final end):
        return transactions
            .where((t) => !t.timestamp.isBefore(start) && !t.timestamp.isAfter(end))
            .toList();
    }
  }

  static String _generateCsv(List<Transaction> transactions) {
    final buffer = StringBuffer(
      'Date,Time,Payee,Amount,Type,Category,Bucket,Notes,Bank,Account,Reference,Is Manual,Created At\n',
    );

    final sorted = List.of(transactions)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final t in sorted) {
      final date = _dateFormat.format(t.timestamp);
      final time = _timeFormat.format(t.timestamp);
      final payee = _escapeCsvField(t.payee);
      final amount = t.amount.toStringAsFixed(2);
      final type = _titleCase(t.type.rawValue.replaceAll('_', ' '));
      final category = _escapeCsvField(t.categoryName ?? '');
      final bucket = t.bucket?.displayName ?? '';
      final notes = _escapeCsvField(t.notes ?? '');
      final bank = _escapeCsvField(t.bankName ?? '');
      final account = _escapeCsvField(t.accountNumber ?? '');
      final reference = _escapeCsvField(t.transactionReference ?? '');
      final isManual = t.isManual ? 'Yes' : 'No';
      final createdAt = _timestampFormat.format(t.createdAt);

      buffer.write(
        '$date,$time,$payee,$amount,$type,$category,$bucket,$notes,$bank,$account,$reference,$isManual,$createdAt\n',
      );
    }

    return buffer.toString();
  }

  static String _escapeCsvField(String field) {
    if (field.isEmpty) return '';
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }

  static String _titleCase(String value) => value
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  static String generateFilename(ExportTimeframe timeframe) {
    final today = _dateFormat.format(DateTime.now());
    switch (timeframe) {
      case AllTimeframe():
        return 'ExLog_All_Transactions_$today.csv';
      case CurrentMonthTimeframe():
        return 'ExLog_${_monthFormat.format(DateTime.now())}_Transactions.csv';
      case CustomMonthTimeframe(year: final year, month: final month):
        final monthName = _monthNameFormat.format(DateTime(year, month));
        return 'ExLog_${monthName}_${year}_Transactions.csv';
      case CustomYearTimeframe(year: final year):
        return 'ExLog_${year}_Transactions.csv';
      case DateRangeTimeframe(start: final start, end: final end):
        final startStr = _dateFormat.format(start);
        final endStr = _dateFormat.format(end);
        return 'ExLog_${startStr}_to_${endStr}_Transactions.csv';
    }
  }
}
