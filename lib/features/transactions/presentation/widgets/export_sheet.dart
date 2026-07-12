import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/services/transaction_csv_exporter.dart';
import '../../domain/entities/transaction.dart';

enum _ExportOption { all, currentMonth, customMonth, customYear, dateRange }

class ExportSheet extends StatefulWidget {
  final List<Transaction> transactions;

  const ExportSheet({super.key, required this.transactions});

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  _ExportOption _selected = _ExportOption.all;
  int _customMonth = DateTime.now().month;
  int _customYear = DateTime.now().year;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isExporting = false;

  ExportTimeframe get _timeframe {
    switch (_selected) {
      case _ExportOption.all:
        return const AllTimeframe();
      case _ExportOption.currentMonth:
        return const CurrentMonthTimeframe();
      case _ExportOption.customMonth:
        return CustomMonthTimeframe(year: _customYear, month: _customMonth);
      case _ExportOption.customYear:
        return CustomYearTimeframe(year: _customYear);
      case _ExportOption.dateRange:
        return DateRangeTimeframe(
          start: _rangeStart ?? DateTime.now().subtract(const Duration(days: 30)),
          end: _rangeEnd ?? DateTime.now(),
        );
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final timeframe = _timeframe;
      final csv = TransactionCsvExporter.exportToCsv(widget.transactions, timeframe);
      final filename = TransactionCsvExporter.generateFilename(timeframe);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], fileNameOverrides: [filename]);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _pickCustomMonth() async {
    var month = _customMonth;
    var year = _customYear;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: DateTime(year, month),
                onDateTimeChanged: (d) {
                  month = d.month;
                  year = d.year;
                },
              ),
            ),
          ],
        ),
      ),
    );
    setState(() {
      _customMonth = month;
      _customYear = year;
    });
  }

  Future<void> _pickCustomYear() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (i) => currentYear - i);
    var picked = _customYear;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: years.indexOf(picked).clamp(0, years.length - 1),
                ),
                onSelectedItemChanged: (i) => picked = years[i],
                children: years
                    .map((y) => Center(child: Text('$y', style: const TextStyle(fontSize: 20))))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
    setState(() => _customYear = picked);
  }

  Future<void> _pickRangeDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _rangeStart : _rangeEnd) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _rangeStart = picked;
      } else {
        _rangeEnd = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
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
                  child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontSize: 17)),
                ),
                const Expanded(
                  child: Text(
                    'Export Transactions',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2,
                  ),
                ),
                CupertinoButton(
                  onPressed: _isExporting ? null : _export,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Export',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _OptionRow(
                          label: 'All Time',
                          selected: _selected == _ExportOption.all,
                          onTap: () => setState(() => _selected = _ExportOption.all),
                        ),
                        const Divider(height: 1, indent: 14, color: AppColors.divider),
                        _OptionRow(
                          label: 'This Month',
                          selected: _selected == _ExportOption.currentMonth,
                          onTap: () => setState(() => _selected = _ExportOption.currentMonth),
                        ),
                        const Divider(height: 1, indent: 14, color: AppColors.divider),
                        _OptionRow(
                          label: 'Custom Month',
                          selected: _selected == _ExportOption.customMonth,
                          trailing: _selected == _ExportOption.customMonth
                              ? _Pill(
                                  label: DateFormat('MMMM yyyy').format(DateTime(_customYear, _customMonth)),
                                  onTap: _pickCustomMonth,
                                )
                              : null,
                          onTap: () => setState(() => _selected = _ExportOption.customMonth),
                        ),
                        const Divider(height: 1, indent: 14, color: AppColors.divider),
                        _OptionRow(
                          label: 'Custom Year',
                          selected: _selected == _ExportOption.customYear,
                          trailing: _selected == _ExportOption.customYear
                              ? _Pill(label: '$_customYear', onTap: _pickCustomYear)
                              : null,
                          onTap: () => setState(() => _selected = _ExportOption.customYear),
                        ),
                        const Divider(height: 1, indent: 14, color: AppColors.divider),
                        _OptionRow(
                          label: 'Date Range',
                          selected: _selected == _ExportOption.dateRange,
                          onTap: () => setState(() => _selected = _ExportOption.dateRange),
                        ),
                        if (_selected == _ExportOption.dateRange) ...[
                          const Divider(height: 1, indent: 14, color: AppColors.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text('From', style: AppTextStyles.body)),
                                _Pill(
                                  label: _rangeStart == null
                                      ? 'Select'
                                      : DateFormat('d MMM yyyy').format(_rangeStart!),
                                  onTap: () => _pickRangeDate(isStart: true),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 14, color: AppColors.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text('To', style: AppTextStyles.body)),
                                _Pill(
                                  label: _rangeEnd == null
                                      ? 'Select'
                                      : DateFormat('d MMM yyyy').format(_rangeEnd!),
                                  onTap: () => _pickRangeDate(isStart: false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
      ),
    );
  }
}
