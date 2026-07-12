import 'package:intl/intl.dart';

import '../entities/transaction.dart';

/// Result of parsing a bank/UPI SMS — either via regex or AI. The orchestrator
/// turns this into a full [Transaction] once userId/category are resolved.
class ParsedSmsResult {
  final double amount;
  final String payee;
  final TransactionType type;
  final String? bankName;
  final String? accountNumber;
  final String? transactionReference;
  final DateTime? timestamp;
  final bool parsedByAI;

  const ParsedSmsResult({
    required this.amount,
    required this.payee,
    required this.type,
    this.bankName,
    this.accountNumber,
    this.transactionReference,
    this.timestamp,
    this.parsedByAI = false,
  });

  ParsedSmsResult copyWith({
    double? amount,
    String? payee,
    TransactionType? type,
    String? bankName,
    String? accountNumber,
    String? transactionReference,
    DateTime? timestamp,
    bool? parsedByAI,
  }) =>
      ParsedSmsResult(
        amount: amount ?? this.amount,
        payee: payee ?? this.payee,
        type: type ?? this.type,
        bankName: bankName ?? this.bankName,
        accountNumber: accountNumber ?? this.accountNumber,
        transactionReference: transactionReference ?? this.transactionReference,
        timestamp: timestamp ?? this.timestamp,
        parsedByAI: parsedByAI ?? this.parsedByAI,
      );
}

class _SmsPattern {
  final String bankName;
  final RegExp debit;
  final RegExp credit;
  final RegExp? atm;
  const _SmsPattern({required this.bankName, required this.debit, required this.credit, this.atm});
}

RegExp _ci(String pattern) => RegExp(pattern, caseSensitive: false, dotAll: false);

/// Ported from iOS `SMSParser.swift` — verbatim per-bank regex patterns, in
/// the same deliberate order (ICICI first to avoid false matches with other
/// banks' looser wording).
class SmsRegexParser {
  const SmsRegexParser._();

  static final List<_SmsPattern> _patterns = [
    // ICICI new format
    _SmsPattern(
      bankName: 'ICICI Bank',
      debit: _ci(r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)\s+debited\s+from.*?(?:on\s+\d{2}-[A-Za-z]{3}-\d{2,4})\s+(.+?)(?:\.?\s+Bal\b|\.$|$)'),
      credit: _ci(r'(?:credited|received).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from|to)\s+([\w\s]+?)(?:on|\.|,|$)'),
      atm: _ci(r'(?:withdrawn).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'),
    ),
    // ICICI legacy format ("...; PAYEE credited")
    _SmsPattern(
      bankName: 'ICICI Bank',
      debit: _ci(r'(?:debited|paid).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?;\s*([A-Za-z0-9\s]+?)\s+credited'),
      credit: _ci(r'(?:credited|received).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from|to)\s+([\w\s]+?)(?:on|\.|,|$)'),
      atm: _ci(r'(?:withdrawn).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'),
    ),
    // HDFC
    _SmsPattern(
      bankName: 'HDFC Bank',
      debit: _ci(r'(?:debited|spent|paid).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:at|to)\s+([\w\s]+?)(?:on|\.|,|$)'),
      credit: _ci(r'(?:credited|received).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from)\s+([\w\s]+?)(?:on|\.|,|$)'),
      atm: _ci(r'(?:withdrawn|cash).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:atm)\s+([\w\s]+?)(?:on|\.|,|$)'),
    ),
    // SBI
    _SmsPattern(
      bankName: 'SBI Bank',
      debit: _ci(r'(?:debited(?:\s+by)?|spent)\s*(?:rs\.?|inr|₹)?\s*([\d,]+\.?\d*).*?(?:trf\s+to|at|to)\s+([A-Z][A-Za-z0-9]*(?:\s+[A-Z][A-Za-z0-9]*)*)(?:\s+(?:Refno|If|on|\.|,)|$)'),
      credit: _ci(r'(?:credited).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from)\s+([\w\s]+?)(?:on|\.|,|$)'),
      atm: _ci(r'(?:cash withdrawn).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'),
    ),
    // Axis
    _SmsPattern(
      bankName: 'Axis Bank',
      debit: _ci(r'(?:debited|spent).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:at|to)\s+([\w\s]+?)(?:on|\.|,|$)'),
      credit: _ci(r'(?:credited).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from)\s+([\w\s]+?)(?:on|\.|,|$)'),
      atm: _ci(r'(?:withdrawn).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'),
    ),
    // UPI (GPay/PhonePe/Paytm/BHIM)
    _SmsPattern(
      bankName: 'UPI',
      debit: _ci(r'(?:sent|paid|transferred).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:to)\s+([\w\s@]+?)(?:on|\.|via|$)'),
      credit: _ci(r'(?:received|got).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from)\s+([\w\s@]+?)(?:on|\.|via|$)'),
    ),
    // Generic fallback pattern
    _SmsPattern(
      bankName: 'Bank',
      debit: _ci(r'(?:debit|debited|dr|spent|paid).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:at|to|towards)\s*([\w\s]+?)(?:on|\.|,|$)'),
      credit: _ci(r'(?:credit|credited|cr|received).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*).*?(?:from|by)\s*([\w\s]+?)(?:on|\.|,|$)'),
      atm: _ci(r'(?:atm|cash|withdrawal|withdrawn).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'),
    ),
  ];

  static const List<String> _prefixesToStrip = [
    'MIN*', 'MPOS*', 'POS*', 'IMPS*', 'NEFT*', 'UPI*', 'BIL*', 'CMS*', 'ACH*', 'ECS*',
  ];

  static const List<String> _bankNameList = [
    'ICICI Bank', 'HDFC Bank', 'SBI Bank', 'Axis Bank', 'Kotak Bank', 'Yes Bank',
    'IDBI Bank', 'Canara Bank', 'Bank of Baroda', 'PNB Bank', 'Union Bank',
    'IndusInd Bank', 'Federal Bank', 'HSBC', 'Citi Bank', 'Standard Chartered',
    'Deutsche Bank', 'Google Pay', 'PhonePe', 'Paytm', 'BHIM', 'WhatsApp Pay', 'Amazon Pay',
  ];

  static const List<String> _transactionKeywords = [
    'debited', 'credited', 'spent', 'paid', 'received', 'withdrawn', 'sent',
    'transferred', 'rs', 'inr', '₹', 'upi',
  ];

  static bool isTransactionSMS(String message) {
    final lower = message.toLowerCase();
    return _transactionKeywords.any((k) => lower.contains(k));
  }

  static String? extractBankName(String message) {
    for (final name in _bankNameList) {
      if (message.toLowerCase().contains(name.toLowerCase())) return name;
    }
    return null;
  }

  static String? extractAccountNumber(String message) {
    var m = _ci(r'(?:acct|a/c|account)\s+([A-Za-z0-9X]+)').firstMatch(message);
    m ??= _ci(r'a/c\s+([A-Za-z0-9X]+)').firstMatch(message);
    return m?.group(1);
  }

  static String? extractTransactionReference(String message) {
    var m = _ci(r'(?:upi|ref|reference|transaction\s+id|ref\s+no|refno)\s*[:=]?\s*([A-Za-z0-9:]+?)(?:\s+|\.|;|,|$)')
        .firstMatch(message);
    m ??= _ci(r'([A-Z0-9]+:[A-Z0-9]+)').firstMatch(message);
    final ref = m?.group(1);
    if (ref == null || ref.length <= 3) return null;
    return ref;
  }

  static DateTime? extractDate(String message) {
    final attempts = <(RegExp, String Function(String))>[
      (_ci(r'\d{2}-[A-Za-z]{3}-\d{2,4}'), (s) => s.split('-')[2].length == 2 ? 'dd-MMM-yy' : 'dd-MMM-yyyy'),
      (_ci(r'\d{2}/\d{2}/\d{2,4}'), (s) => s.split('/')[2].length == 2 ? 'dd/MM/yy' : 'dd/MM/yyyy'),
      (_ci(r'\d{4}-\d{2}-\d{2}'), (_) => 'yyyy-MM-dd'),
      (_ci(r'\d{2}\.\d{2}\.\d{2,4}'), (s) => s.split('.')[2].length == 2 ? 'dd.MM.yy' : 'dd.MM.yyyy'),
    ];
    for (final (regex, formatFor) in attempts) {
      final match = regex.firstMatch(message);
      if (match == null) continue;
      final raw = match.group(0)!;
      try {
        return DateFormat(formatFor(raw), 'en_US').parseStrict(raw);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static bool isSelfTransfer(String payee, List<String> selfNames) {
    final normalizedPayee = payee.toLowerCase().trim();
    for (final selfName in selfNames) {
      final normalizedSelf = selfName.toLowerCase().trim();
      if (normalizedSelf.isEmpty) continue;
      if (normalizedPayee.contains(normalizedSelf) || normalizedSelf.contains(normalizedPayee)) {
        return true;
      }
    }
    return false;
  }

  static String cleanMerchantName(String rawName) {
    var name = rawName.trim();
    for (final prefix in _prefixesToStrip) {
      if (name.toUpperCase().startsWith(prefix)) {
        name = name.substring(prefix.length).trim();
        break;
      }
    }
    name = name.replaceFirst(_ci(r'\s+[A-Za-z]\.?\s*$'), '');
    name = name.replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
    while (name.contains('  ')) {
      name = name.replaceAll('  ', ' ');
    }
    final words = name.split(' ').map((w) {
      if (w.isEmpty) return w;
      if (RegExp(r'^\d+$').hasMatch(w)) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    });
    return words.join(' ').trim();
  }

  static String? extractPayeeWithProperCase(String message) {
    // Only the first (date-based) pattern is case-insensitive in iOS's
    // source. The remaining pairs are deliberately case-SENSITIVE — each
    // pair's uppercase/lowercase variants exist specifically so an
    // upper-vs-lower distinction is preserved (e.g. matching "RAM KUMAR"
    // without also swallowing a trailing lowercase word like "on"/"via").
    // Wrapping all of these in caseSensitive:false (as an earlier version of
    // this file did) collapses that distinction — Dart folds `[A-Z]` to also
    // match lowercase under caseSensitive:false — and over-captures trailing
    // lowercase words into the payee.
    final attempts = <RegExp>[
      _ci(r'on\s+\d{2}-[A-Za-z]{3}-\d{2,4}\s+(.+?)(?:\.?\s+Bal\b|\.$|$)'),
      RegExp(r';\s+([A-Z0-9][A-Za-z0-9]*(?:\s+[A-Z0-9][A-Za-z0-9]*)*)\s+credited'),
      RegExp(r';\s+([a-z][a-z0-9]*(?:\s+[a-z][a-z0-9]*)*)\s+credited'),
      RegExp(r'([A-Z0-9][A-Za-z0-9]*(?:\s+[A-Z0-9][A-Za-z0-9]*)*)\s+credited'),
      RegExp(r'([a-z][a-z0-9]*(?:\s+[a-z][a-z0-9]*)*)\s+credited'),
      RegExp(r'(?:to|credited to)\s+([A-Z0-9][A-Za-z0-9]*(?:\s+[A-Z0-9][A-Za-z0-9]*)*)(?:\s|upi|;|$)'),
      RegExp(r'(?:to|credited to)\s+([a-z][a-z0-9]*(?:\s+[a-z][a-z0-9]*)*)(?:\s|upi|;|$)'),
      RegExp(r'(\b[A-Z0-9]+(?:\s+[A-Z0-9]+)+\b)(?:\s+credited|\s+debited|\s+upi|;|$)'),
    ];
    for (final regex in attempts) {
      final m = regex.firstMatch(message);
      final raw = m?.group(1);
      if (raw == null) continue;
      final cleaned = cleanMerchantName(raw);
      if (cleaned.length > 2 && !RegExp(r'^[\d\s]+$').hasMatch(cleaned)) return cleaned;
    }
    return null;
  }

  static double? _parseAmount(String raw) => double.tryParse(raw.replaceAll(',', ''));

  static ParsedSmsResult? _tryParseFallback(String message) {
    final amountMatch = _ci(r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)').firstMatch(message);
    final amount = amountMatch != null ? _parseAmount(amountMatch.group(1)!) : null;
    if (amount == null || amount <= 0) return null;

    String? payee;
    final payeeAttempts = <RegExp>[
      _ci(r'(?:on\s+\d{2}-[A-Za-z]{3}-\d{2,4}\s+)?([A-Z]{2,}\*[A-Za-z0-9]+)(?:\s|\.|,|$)'),
      _ci(r'([A-Z][A-Za-z\s]+?)\s+credited'),
      _ci(r'credited\s+([A-Za-z\s]+?)(?:\s+upi|;|\.|,|$)'),
      _ci(r'(?:to|at)\s+([A-Za-z\s]+?)(?:\s+(?:on|at|via|upi)|;|\.|,|$)'),
      _ci(r'(?:from|by)\s+([A-Za-z\s]+?)(?:\s+(?:on|via)|;|\.|,|$)'),
      _ci(r'\b([A-Z][A-Za-z\s]{2,}?)(?:\s+(?:credited|debited|upi|call|on)|;|\.|,|$)'),
    ];
    for (final regex in payeeAttempts) {
      final m = regex.firstMatch(message);
      final raw = m?.group(1)?.trim();
      if (raw == null) continue;
      final digitsStripped = raw.replaceAll(RegExp(r'\d'), '').trim();
      if (digitsStripped.length <= 2) continue;
      final upper = raw.toUpperCase();
      if (upper == 'BANK' || upper == 'ACCT' || upper == 'ACCOUNT') continue;
      payee = raw;
      break;
    }
    payee ??= 'Unknown';

    final lower = message.toLowerCase();
    TransactionType type;
    if (lower.contains('credited') || lower.contains('received') || lower.contains('got')) {
      type = TransactionType.credit;
    } else if (lower.contains('atm') || lower.contains('withdrawn') || lower.contains('cash')) {
      type = TransactionType.cashWithdrawal;
    } else {
      type = TransactionType.expense;
    }

    return ParsedSmsResult(amount: amount, payee: cleanMerchantName(payee), type: type);
  }

  /// Tries each bank pattern in order, then the last-resort fallback. Every
  /// return path is enriched with bankName/accountNumber/transactionReference
  /// before returning — these are re-extracted from the raw text independent
  /// of which pattern matched (matching iOS, where the same three extractors
  /// run regardless of which bank pattern produced the amount/payee).
  static ParsedSmsResult? parseSMS(String message, {required List<String> selfNames}) {
    final result = _matchPatterns(message, selfNames) ?? _tryParseFallback(message);
    if (result == null) return null;
    return result.copyWith(
      bankName: extractBankName(message),
      accountNumber: extractAccountNumber(message),
      transactionReference: extractTransactionReference(message),
    );
  }

  static ParsedSmsResult? _matchPatterns(String message, List<String> selfNames) {
    for (final pattern in _patterns) {
      final debitMatch = pattern.debit.firstMatch(message);
      if (debitMatch != null && debitMatch.groupCount >= 1) {
        final amount = _parseAmount(debitMatch.group(1) ?? '');
        if (amount != null && amount > 0) {
          final rawPayee = debitMatch.groupCount >= 2 ? debitMatch.group(2) : null;
          final payee = cleanMerchantName(extractPayeeWithProperCase(message) ?? rawPayee ?? 'Unknown');
          final type = isSelfTransfer(payee, selfNames) ? TransactionType.selfTransfer : TransactionType.expense;
          return ParsedSmsResult(amount: amount, payee: payee.isEmpty ? 'Unknown' : payee, type: type);
        }
      }

      final creditMatch = pattern.credit.firstMatch(message);
      if (creditMatch != null && creditMatch.groupCount >= 1) {
        final amount = _parseAmount(creditMatch.group(1) ?? '');
        if (amount != null && amount > 0) {
          final rawPayee = creditMatch.groupCount >= 2 ? creditMatch.group(2) : null;
          final payee = cleanMerchantName(extractPayeeWithProperCase(message) ?? rawPayee ?? 'Unknown');
          return ParsedSmsResult(
            amount: amount,
            payee: payee.isEmpty ? 'Unknown' : payee,
            type: TransactionType.credit,
          );
        }
      }

      final atmMatch = pattern.atm?.firstMatch(message);
      if (atmMatch != null && atmMatch.groupCount >= 1) {
        final amount = _parseAmount(atmMatch.group(1) ?? '');
        if (amount != null && amount > 0) {
          final rawPayee = atmMatch.groupCount >= 2 ? atmMatch.group(2) : null;
          final payee = rawPayee != null ? cleanMerchantName(rawPayee) : 'ATM';
          return ParsedSmsResult(
            amount: amount,
            payee: payee.isEmpty ? 'ATM' : payee,
            type: TransactionType.cashWithdrawal,
          );
        }
      }
    }
    return null;
  }
}
