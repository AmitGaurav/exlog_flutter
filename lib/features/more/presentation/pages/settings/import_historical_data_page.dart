import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection.dart';
import '../../../../categories/domain/repositories/category_repository.dart';
import '../../../../transactions/domain/entities/transaction.dart';
import '../../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../data/services/historical_import_parser.dart';

class ImportHistoricalDataPage extends StatefulWidget {
  const ImportHistoricalDataPage({super.key});

  @override
  State<ImportHistoricalDataPage> createState() => _ImportHistoricalDataPageState();
}

class _ImportHistoricalDataPageState extends State<ImportHistoricalDataPage> {
  bool _isImporting = false;
  String _status = '';
  bool _success = false;

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _status = 'Could not read the selected file.';
        _success = false;
      });
      return;
    }

    List<ParsedHistoricalRow> rows;
    try {
      rows = HistoricalImportParser.parse(utf8.decode(bytes));
    } on FormatException catch (e) {
      setState(() {
        _status = e.message;
        _success = false;
      });
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
            'You are about to import ${rows.length} transactions from the selected CSV file. This action cannot be undone. Are you sure you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _importRows(rows);
  }

  Future<void> _importRows(List<ParsedHistoricalRow> rows) async {
    setState(() {
      _isImporting = true;
      _status = 'Loading categories...';
    });

    final categoryRepository = sl<CategoryRepository>();
    final transactionRepository = sl<TransactionRepository>();
    final categories = await categoryRepository.getCategories();
    final categoryMap = {for (final c in categories) c.name.toLowerCase(): c};

    setState(() => _status = 'Importing ${rows.length} transactions...');

    var successCount = 0;
    for (final row in rows) {
      final matchedCategory = row.categoryName == null ? null : categoryMap[row.categoryName!.toLowerCase()];
      final transaction = Transaction.create(
        amount: row.amount,
        payee: row.payee,
        categoryId: matchedCategory?.id,
        categoryName: matchedCategory?.name ?? row.categoryName,
        bucket: matchedCategory?.bucket,
        timestamp: row.date,
        type: row.type,
        notes: row.notes,
        isManual: true,
        userId: '',
      );
      try {
        await transactionRepository.createTransaction(transaction);
        successCount++;
      } catch (_) {
        // Continue importing remaining rows, matching iOS's per-row loop.
      }
    }

    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _success = successCount > 0;
      _status = '✅ Successfully imported $successCount of ${rows.length} transactions';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Center(child: Icon(Icons.file_download_outlined, size: 60, color: AppColors.primary)),
          const SizedBox(height: 16),
          const Center(
            child: Text('Import Historical Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Import your expense history from a CSV file',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          const Text('CSV Format:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'Date, Amount, Payee, Category, Type, Notes\n'
              '01/01/25, 15, Big Basket, , Expense,\n'
              '02/01/25, 15, Paan, , Expense,\n'
              '03/01/25, 60, Paan, , Expense,',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• Date: dd/MM/yy or dd/MM/yyyy\n• Amount: Numeric value\n• Type: Expense, Income, Self Transfer, Cash Withdrawal',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_success ? AppColors.income : const Color(0xFFFF9500)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _success ? AppColors.income : const Color(0xFFFF9500)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickAndImport,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Select CSV File', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_isImporting) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
