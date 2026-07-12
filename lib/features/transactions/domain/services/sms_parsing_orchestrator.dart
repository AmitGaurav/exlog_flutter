import '../../../more/domain/entities/user_profile.dart';
import '../entities/transaction.dart';
import 'banking_sms_detector.dart';
import 'llm_sms_parser.dart';
import 'sms_regex_parser.dart';

/// Ported fallback chain from iOS `EnhancedSMSParser`/
/// `TransactionViewModel.parseSMSAndCreateTransaction`: banking gate first →
/// AI (if enabled+configured) → regex fallback. If the AI explicitly says
/// "not a transaction", that's a hard stop — no regex fallback, matching iOS.
class SmsParsingOrchestrator {
  final LlmSmsParser _llmParser;

  SmsParsingOrchestrator({LlmSmsParser? llmParser}) : _llmParser = llmParser ?? LlmSmsParser();

  Future<ParsedSmsResult?> parse({
    required String message,
    required AIParserConfig aiConfig,
    required String apiKey,
    required List<String> selfNames,
  }) async {
    if (!BankingSmsDetector.classifyBankingSMS(message).isBankingRelated) return null;

    ParsedSmsResult? result;

    if (aiConfig.isEnabled && apiKey.isNotEmpty) {
      try {
        final llmResult = await _llmParser.parseSMS(message, aiConfig, apiKey);
        if (llmResult != null) {
          if (!llmResult.isTransactionalSMS) return null;
          result = _convertLlmResult(llmResult, message, selfNames);
        }
      } catch (_) {
        // Falls through to regex, matching iOS.
      }
    }

    result ??= SmsRegexParser.parseSMS(message, selfNames: selfNames);
    if (result == null) return null;

    // Date is always re-extracted from the raw text, overriding both the
    // regex and AI paths, exactly like iOS's TransactionViewModel does.
    final reExtractedDate = SmsRegexParser.extractDate(message);
    return result.copyWith(timestamp: reExtractedDate ?? result.timestamp);
  }

  ParsedSmsResult? _convertLlmResult(LlmSmsParseResult llm, String message, List<String> selfNames) {
    final amount = llm.amount;
    if (amount == null || amount <= 0) return null;

    var type = _typeFromString(llm.transactionType) ?? _determineTypeFromMessage(message);

    final rawPayee = llm.payee?.trim();
    var payee = (rawPayee == null || rawPayee.isEmpty) ? 'Unknown' : SmsRegexParser.cleanMerchantName(rawPayee);
    if (payee.isEmpty) payee = 'Unknown';

    if (SmsRegexParser.isSelfTransfer(payee, selfNames)) type = TransactionType.selfTransfer;

    return ParsedSmsResult(
      amount: amount,
      payee: payee,
      type: type,
      bankName: llm.bankName,
      accountNumber: SmsRegexParser.extractAccountNumber(message),
      transactionReference: llm.transactionReference,
      timestamp: llm.parsedDate,
      parsedByAI: true,
    );
  }

  TransactionType? _typeFromString(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'expense':
        return TransactionType.expense;
      case 'credit':
        return TransactionType.credit;
      case 'cash_withdrawal':
        return TransactionType.cashWithdrawal;
      case 'self_transfer':
        return TransactionType.selfTransfer;
      case 'investment':
        // No distinct "investment" type modeled in Flutter's TransactionType
        // yet (out of scope for this phase) — closest safe fallback.
        return TransactionType.expense;
      default:
        return null;
    }
  }

  TransactionType _determineTypeFromMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('credited') || lower.contains('received')) return TransactionType.credit;
    if (lower.contains('atm') || lower.contains('withdrawn') || lower.contains('cash withdrawal')) {
      return TransactionType.cashWithdrawal;
    }
    return TransactionType.expense;
  }

  void close() => _llmParser.close();
}
