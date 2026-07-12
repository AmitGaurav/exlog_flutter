import 'package:intl/intl.dart';

import '../../../transactions/domain/entities/transaction.dart';

/// A row parsed from the historical-import CSV, before category resolution.
class ParsedHistoricalRow {
  final DateTime date;
  final double amount;
  final String payee;
  final String? categoryName;
  final TransactionType type;
  final String? notes;

  ParsedHistoricalRow({
    required this.date,
    required this.amount,
    required this.payee,
    this.categoryName,
    required this.type,
    this.notes,
  });
}

/// Ported from iOS `CSVParser.parseTransactions`. Expects 6 comma-separated
/// columns: `Date, Amount, Payee, Category, Type, Notes` — NOT the same
/// format `TransactionCsvExporter` produces (13 columns, different order),
/// so an ExLog export cannot be re-imported as-is.
class HistoricalImportParser {
  static const _dateFormats = [
    'dd/MM/yy',
    'dd/MM/yyyy',
    'yyyy-MM-dd',
    'MM/dd/yy',
    'MM/dd/yyyy',
    'dd-MM-yy',
    'dd-MM-yyyy',
  ];

  /// Throws a [FormatException] with a human-readable message on failure.
  static List<ParsedHistoricalRow> parse(String csvContent) {
    final lines = csvContent.split(RegExp(r'\r\n|\r|\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      throw const FormatException('The CSV file is empty.');
    }

    // Skip a header row if the first column isn't a parseable date.
    var startIndex = 0;
    if (lines.isNotEmpty && _parseDate(lines.first.split(',').first.trim()) == null) {
      startIndex = 1;
    }

    final rows = <ParsedHistoricalRow>[];
    for (var i = startIndex; i < lines.length; i++) {
      final cols = lines[i].split(',').map((c) => c.trim()).toList();
      if (cols.length < 3) continue;

      final date = _parseDate(cols[0]);
      final amount = double.tryParse(cols.length > 1 ? cols[1] : '');
      if (date == null || amount == null) continue;

      final payee = cols.length > 2 ? cols[2] : '';
      final categoryName = cols.length > 3 && cols[3].isNotEmpty ? cols[3] : null;
      final typeString = cols.length > 4 ? cols[4] : '';
      final notes = cols.length > 5 && cols[5].isNotEmpty ? cols[5] : null;

      rows.add(ParsedHistoricalRow(
        date: date,
        amount: amount,
        payee: payee,
        categoryName: categoryName,
        type: _normalizeType(typeString),
        notes: notes,
      ));
    }

    if (rows.isEmpty) {
      throw const FormatException('No valid transaction rows found in the CSV file.');
    }
    return rows;
  }

  static DateTime? _parseDate(String raw) {
    for (final pattern in _dateFormats) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static TransactionType _normalizeType(String raw) {
    final v = raw.toLowerCase().trim();
    if (v == 'income' || v == 'credit' || v == 'deposit') return TransactionType.credit;
    if (v == 'self transfer' || v == 'transfer' || v == 'self_transfer') return TransactionType.selfTransfer;
    if (v == 'cash withdrawal' || v == 'atm' || v == 'cash_withdrawal') return TransactionType.cashWithdrawal;
    return TransactionType.expense; // expense, debit, payment, or unrecognized default
  }
}
