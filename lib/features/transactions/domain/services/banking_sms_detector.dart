/// Ported from iOS `BankingSMSDetector.swift`. First-pass gate every SMS goes
/// through before any parsing is attempted — deliberately permissive (better
/// a false positive than a missed transaction), see [isBankingSMS].
enum BankingSmsType {
  bankTransaction,
  upiTransaction,
  genericTransaction,
  bankNotification,
  nonBanking;

  bool get isBankingRelated => this != BankingSmsType.nonBanking;
}

class BankingSmsDetector {
  const BankingSmsDetector._();

  static const List<String> bankNames = [
    'hdfc', 'icici', 'sbi', 'axis', 'kotak', 'yes bank', 'idbi',
    'bank of baroda', 'bob', 'punjab national bank', 'pnb', 'union bank',
    'canara', 'indian bank', 'central bank', 'indusind', 'federal bank',
    'hsbc', 'citi', 'standard chartered', 'scbl', 'deutsche', 'abn amro',
    'rbl bank',
  ];

  static const List<String> upiProviders = [
    'google pay', 'googlepay', 'phonepe', 'paytm', 'bhim', 'whatsapp pay',
    'amazon pay', 'flipkart', 'razorpay', 'instamojo', 'imobile', 'mobikwik',
  ];

  static const List<String> transactionKeywords = [
    'debited', 'credited', 'transaction', 'paid', 'received', 'transfer',
    'withdrawn', 'deposited', 'balance', 'account', 'card', 'spending',
    'limit', 'due', 'invoice', 'receipt', 'payment', 'refund', 'reversal',
    'charges', 'interest', 'upi', 'atm', 'emi', 'installment',
  ];

  static const List<String> currencyPatterns = ['rs', '₹', 'inr', 'rupee'];

  static const List<String> notificationKeywords = [
    'otp', 'alert', 'verification', 'confirm', 'urgent', 'fraud',
    'suspicious', 'unusual', 'security', 'update', 'expire', 'activation',
  ];

  static bool _isBankNamePresent(String lower) =>
      bankNames.any((b) => lower.contains(b));

  static bool _isUpiProviderPresent(String lower) =>
      upiProviders.any((p) => lower.contains(p));

  static bool _hasTransactionKeyword(String lower) =>
      transactionKeywords.any((k) => lower.contains(k));

  static bool _hasCurrencyPattern(String lower) =>
      lower.contains('₹') ||
      currencyPatterns.any((c) => lower.contains(c)) ||
      RegExp(r'\d+(?:,\d{3})*').hasMatch(lower);

  static bool _hasNotificationKeyword(String lower) =>
      notificationKeywords.any((k) => lower.contains(k));

  static bool _hasTransactionPattern(String message) {
    if (RegExp(r'(rs|₹|inr)\s*\d+', caseSensitive: false).hasMatch(message)) return true;
    return RegExp(r'(?:debited|credited|paid|received|transferred|withdrawn)', caseSensitive: false)
        .hasMatch(message);
  }

  static bool isBankingSMS(String message) {
    final lower = message.toLowerCase();
    if (_isBankNamePresent(lower)) return true;
    if (_isUpiProviderPresent(lower)) return true;
    if (_hasTransactionKeyword(lower) && _hasCurrencyPattern(lower)) return true;
    if (_hasTransactionPattern(message)) return true;
    return false;
  }

  static BankingSmsType classifyBankingSMS(String message) {
    final lower = message.toLowerCase();

    if (_isBankNamePresent(lower)) {
      return _hasTransactionKeyword(lower)
          ? BankingSmsType.bankTransaction
          : BankingSmsType.bankNotification;
    }
    if (_isUpiProviderPresent(lower)) return BankingSmsType.upiTransaction;
    if (_hasTransactionKeyword(lower) && _hasCurrencyPattern(lower)) {
      return BankingSmsType.genericTransaction;
    }
    if (_hasNotificationKeyword(lower)) return BankingSmsType.bankNotification;
    return BankingSmsType.nonBanking;
  }
}
