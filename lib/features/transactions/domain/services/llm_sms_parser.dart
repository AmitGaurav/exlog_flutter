import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../more/domain/entities/user_profile.dart';

class LlmSmsParseResult {
  final bool isTransactionalSMS;
  final double? amount;
  final String? bankName;
  final String? payee;
  final String? timestamp;
  final String? transactionReference;
  final String? transactionType;

  const LlmSmsParseResult({
    required this.isTransactionalSMS,
    this.amount,
    this.bankName,
    this.payee,
    this.timestamp,
    this.transactionReference,
    this.transactionType,
  });

  factory LlmSmsParseResult.fromJson(Map<String, dynamic> json) => LlmSmsParseResult(
        isTransactionalSMS: json['isTransactionalSMS'] as bool? ?? false,
        amount: (json['amount'] as num?)?.toDouble(),
        bankName: json['bankName'] as String?,
        payee: json['payee'] as String?,
        timestamp: json['timestamp'] as String?,
        transactionReference: json['transactionReference'] as String?,
        transactionType: json['transactionType'] as String?,
      );

  DateTime? get parsedDate {
    if (timestamp == null) return null;
    for (final pattern in ['yyyy-MM-dd', 'dd-MM-yyyy', 'dd-MM-yy', 'dd-MMM-yy']) {
      try {
        return DateFormat(pattern, 'en_US').parseStrict(timestamp!);
      } catch (_) {
        continue;
      }
    }
    try {
      return DateTime.parse(timestamp!);
    } catch (_) {
      return null;
    }
  }
}

class LlmSmsParserException implements Exception {
  final String message;
  const LlmSmsParserException(this.message);
  @override
  String toString() => 'LlmSmsParserException: $message';
}

/// Ported from iOS `LLMSMSParser.swift` — same prompt (including the
/// amount-vs-balance and debited-vs-credited-recipient disambiguation rules)
/// and same 5 provider REST APIs, called directly with the user's own key.
class LlmSmsParser {
  final http.Client _client;
  LlmSmsParser({http.Client? client}) : _client = client ?? http.Client();

  static String _prompt(String message) => '''
You are a financial transaction SMS parser. Extract structured information from Indian bank SMS messages.

RULES:
1. Identify if the SMS is a FINANCIAL TRANSACTION (debit/credit/ATM withdrawal/UPI payment)
2. Extract: amount, bank name, payee/merchant, date, reference number, transaction type
3. Return ONLY valid JSON in the exact format below
4. Set isTransactionalSMS=false for: OTP, promotions, balance inquiries, general alerts
5. Use null for fields that cannot be extracted
6. Amount: extract numeric value only (remove Rs/INR symbols and commas). "Rs. 1,22,887.83" -> 122887.83
7. Dates: convert to YYYY-MM-DD. "03-Mar-26" -> "2026-03-03"
8. Bank: extract full name e.g. "HDFC Bank", "ICICI Bank"
9. Payee: clean merchant name — remove prefixes (MIN*, MPOS*, POS*, UPI*, BIL*), trailing abbreviations (I., P., L.), format as proper case
10. The transaction amount is the FIRST amount, NOT the balance. "Rs. 381.97 debited...Bal Rs. 1,22,887.83" -> 381.97

TRANSACTION TYPE RULES — Determine the type based on the OVERALL meaning of the SMS:
- "expense": Money DEBITED/SPENT from the account (purchases, bill payments, UPI debits). If the account is debited, it's an expense regardless of other words.
- "credit": Money RECEIVED/CREDITED INTO the account (salary, refunds, incoming transfers where YOUR account is credited)
- "cash_withdrawal": ATM withdrawals or cash withdrawals
- "self_transfer": Transfer between own accounts (NEFT/IMPS to self)
- "investment": Stock purchases, mutual fund SIPs, trading transactions

IMPORTANT: "Acct XX720 debited for Rs 30.00...ROMI TRIPATHI credited" means YOUR account was DEBITED (expense), not credit. The word "credited" here refers to the RECIPIENT, not you.

SMS: "$message"

JSON FORMAT:
{
  "isTransactionalSMS": true or false,
  "amount": number or null,
  "bankName": "string" or null,
  "payee": "string" or null,
  "timestamp": "YYYY-MM-DD" or null,
  "transactionReference": "string" or null,
  "transactionType": "expense" or "credit" or "cash_withdrawal" or "self_transfer" or "investment" or null
}''';

  Future<LlmSmsParseResult?> parseSMS(String message, AIParserConfig config, String apiKey) async {
    if (!config.isEnabled || apiKey.isEmpty) return null;
    final text = _prompt(message);
    switch (config.provider) {
      case LLMProvider.openai:
        return _callOpenAiCompatible(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: apiKey,
          model: config.model,
          prompt: text,
        );
      case LLMProvider.groq:
        return _callOpenAiCompatible(
          endpoint: 'https://api.groq.com/openai/v1/chat/completions',
          apiKey: apiKey,
          model: config.model,
          prompt: text,
        );
      case LLMProvider.mistral:
        return _callOpenAiCompatible(
          endpoint: 'https://api.mistral.ai/v1/chat/completions',
          apiKey: apiKey,
          model: config.model,
          prompt: text,
        );
      case LLMProvider.anthropic:
        return _callAnthropic(apiKey: apiKey, model: config.model, prompt: text);
      case LLMProvider.gemini:
        return _callGemini(apiKey: apiKey, model: config.model, prompt: text);
    }
  }

  Future<LlmSmsParseResult?> _callOpenAiCompatible({
    required String endpoint,
    required String apiKey,
    required String model,
    required String prompt,
  }) async {
    final response = await _client.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.1,
        'max_tokens': 300,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': 'You are a JSON-only financial SMS parser. Return ONLY valid JSON, no other text.'},
          {'role': 'user', 'content': prompt},
        ],
      }),
    );
    if (response.statusCode != 200) {
      throw LlmSmsParserException('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (body['choices'] as List)[0]['message']['content'] as String;
    return LlmSmsParseResult.fromJson(jsonDecode(content) as Map<String, dynamic>);
  }

  Future<LlmSmsParseResult?> _callAnthropic({
    required String apiKey,
    required String model,
    required String prompt,
  }) async {
    final response = await _client.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 300,
        'messages': [
          {'role': 'user', 'content': '$prompt\n\nReturn ONLY the JSON, nothing else.'},
        ],
      }),
    );
    if (response.statusCode != 200) {
      throw LlmSmsParserException('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    var text = (body['content'] as List)[0]['text'] as String;
    text = _stripMarkdownCodeBlock(text);
    return LlmSmsParseResult.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  Future<LlmSmsParseResult?> _callGemini({
    required String apiKey,
    required String model,
    required String prompt,
  }) async {
    final response = await _client.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 1024,
          'responseMimeType': 'application/json',
          'thinkingConfig': {'thinkingBudget': 0},
        },
      }),
    );
    if (response.statusCode != 200) {
      throw LlmSmsParserException('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['candidates'] as List)[0]['content']['parts'][0]['text'] as String;
    return LlmSmsParseResult.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  void close() => _client.close();

  String _stripMarkdownCodeBlock(String text) {
    var t = text.trim();
    if (t.startsWith('```json')) t = t.substring(7);
    if (t.startsWith('```')) t = t.substring(3);
    if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    return t.trim();
  }
}

