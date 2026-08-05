import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_key_obfuscator.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../more/domain/entities/user_profile.dart';
import '../../../more/domain/repositories/payee_mapping_repository.dart';
import '../../../more/presentation/bloc/user_profile_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/sms_parsing_orchestrator.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

/// Matches iOS's `SMSImportSheetView` — paste-a-bank-SMS flow reachable from
/// the Transactions "+" menu. Shows a display-only "Imported this month"
/// counter (no quota enforcement per project decision), runs the SMS through
/// [SmsParsingOrchestrator] (AI-first, regex fallback), blocks on an exact
/// `transactionReference` duplicate match, and otherwise creates the
/// transaction via the existing [TransactionBloc].
class ImportSmsSheet extends StatefulWidget {
  const ImportSmsSheet({super.key});

  @override
  State<ImportSmsSheet> createState() => _ImportSmsSheetState();
}

class _ImportSmsSheetState extends State<ImportSmsSheet> {
  final _controller = TextEditingController();
  late final SmsParsingOrchestrator _orchestrator;

  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;
  int _importsThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _orchestrator = SmsParsingOrchestrator();
    _controller.addListener(() => setState(() {}));
    _loadUsage();
  }

  @override
  void dispose() {
    _orchestrator.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    final count = await sl<TransactionRepository>().getSmsImportUsageThisMonth();
    if (mounted) setState(() => _importsThisMonth = count);
  }

  Future<void> _process() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final profile = context.read<UserProfileBloc>().state.profile;
      final aiConfig = profile?.aiParserConfig ?? const AIParserConfig();
      final apiKey = deobfuscateApiKey(aiConfig.apiKeyObfuscated);
      final selfNames = profile?.selfNames ?? const <String>[];

      final parsed = await _orchestrator.parse(
        message: text,
        aiConfig: aiConfig,
        apiKey: apiKey,
        selfNames: selfNames,
      );

      if (parsed == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Could not detect a transaction in this SMS. Please check the message and try again.';
        });
        return;
      }

      if (parsed.transactionReference != null) {
        final existing =
            await sl<TransactionRepository>().findByTransactionReference(parsed.transactionReference!);
        if (existing != null) {
          final fmt = DateFormat('d MMM yyyy \'at\' h:mm a');
          setState(() {
            _isProcessing = false;
            _errorMessage = '⚠️ Duplicate Transaction Detected\n\n'
                'Transaction ID: ${parsed.transactionReference}\n\n'
                'This transaction is already saved in the database.\n'
                '• Amount: ₹${NumberFormat('#,##,##0.00').format(existing.amount)}\n'
                '• Payee: ${existing.payee}\n'
                '• Date: ${fmt.format(existing.timestamp)}\n\n'
                'The same transaction cannot be added twice.';
          });
          return;
        }
      }

      String? categoryId;
      String? categoryName = 'Others';
      final mappings = await sl<PayeeMappingRepository>().getMappings();
      for (final mapping in mappings) {
        if (mapping.matches(parsed.payee)) {
          categoryId = mapping.categoryId;
          categoryName = mapping.categoryName ?? mapping.categoryId;
          break;
        }
      }

      BucketType? bucket;
      if (categoryId != null && mounted) {
        for (final c in context.read<CategoryBloc>().state.categories) {
          if (c.id == categoryId) {
            bucket = c.bucket;
            break;
          }
        }
      }

      final transaction = Transaction.create(
        amount: parsed.amount,
        payee: parsed.payee,
        categoryId: categoryId,
        categoryName: categoryName,
        bucket: bucket,
        timestamp: parsed.timestamp ?? DateTime.now(),
        type: parsed.type,
        isManual: false,
        userId: sl<FirebaseAuth>().currentUser?.uid ?? '',
        bankName: parsed.bankName,
        accountNumber: parsed.accountNumber,
        transactionReference: parsed.transactionReference,
        parsedByAI: parsed.parsedByAI,
        importSource: 'sms_paste',
        smsRaw: text,
      );

      if (!mounted) return;
      context.read<TransactionBloc>().add(TransactionAddRequested(transaction));
      await sl<TransactionRepository>().incrementSmsImportUsage();

      setState(() {
        _isProcessing = false;
        _successMessage = 'Transaction created successfully! ✅';
        _importsThisMonth += 1;
      });

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to create transaction. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: const Text('Done', style: TextStyle(color: AppColors.primary, fontSize: 17)),
                  ),
                  const Expanded(
                    child: Text('Import SMS', textAlign: TextAlign.center, style: AppTextStyles.heading2),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SMS Imported: $_importsThisMonth this month',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paste Bank SMS', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Text(
                            'Copy an SMS from your bank or UPI app and paste it below. The app will '
                            'extract transaction details and create the transaction automatically.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('SMS Text', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 6,
                        minLines: 4,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                          hintText: 'Paste your bank SMS here...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_controller.text.length} characters',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: _controller.text.isEmpty ? null : () => _controller.clear(),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.expense, fontSize: 13)),
                      ),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.income.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_successMessage!, style: const TextStyle(color: AppColors.income, fontSize: 13)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Fixed footer (outside the scroll area, not inline at the end of
            // the SMS text content) so Cancel/Create Transaction stay visible
            // above the keyboard instead of requiring a scroll to reach them
            // — the sheet's own keyboard-avoidance wasn't reliably shrinking
            // this DraggableScrollableSheet, so the inset is applied here
            // explicitly, same as the Edit Transaction sheet fix.
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_controller.text.trim().isEmpty || _isProcessing) ? null : _process,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create Transaction'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
