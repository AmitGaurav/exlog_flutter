import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../categories/domain/entities/category.dart' show Category, BucketType;
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

class FilterSheet extends StatefulWidget {
  final TransactionFilter initialFilter;
  final List<Transaction> transactions;

  const FilterSheet({
    super.key,
    required this.initialFilter,
    required this.transactions,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateRangeOption _dateRange;
  int? _selectedYear;
  DateTime? _customStart;
  DateTime? _customEnd;
  TransactionType? _type;
  String? _categoryId;

  static const _quickRanges = [
    DateRangeOption.today,
    DateRangeOption.thisWeek,
    DateRangeOption.thisMonth,
    DateRangeOption.last3Months,
    DateRangeOption.last6Months,
    DateRangeOption.thisYear,
    DateRangeOption.all,
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    _dateRange = f.dateRange;
    _selectedYear = f.selectedYear;
    _customStart = f.customStart;
    _customEnd = f.customEnd;
    _type = f.type;
    _categoryId = f.categoryId;
  }

  TransactionFilter get _pendingFilter => TransactionFilter(
        dateRange: _dateRange,
        selectedYear: _selectedYear,
        customStart: _customStart,
        customEnd: _customEnd,
        type: _type,
        categoryId: _categoryId,
        searchText: widget.initialFilter.searchText,
      );

  int get _matchCount => widget.transactions.where(_pendingFilter.matches).length;

  void _selectQuickRange(DateRangeOption option) {
    setState(() {
      _dateRange = option;
      _selectedYear = null;
      _customStart = null;
      _customEnd = null;
    });
  }

  Future<void> _pickYear(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final years = List.generate(11, (i) => currentYear - i);
    var picked = _selectedYear ?? currentYear;
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
                  initialItem: years.indexOf(picked),
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
    setState(() {
      _dateRange = DateRangeOption.specificYear;
      _selectedYear = picked;
      _customStart = null;
      _customEnd = null;
    });
  }

  void _toggleCustomRange() {
    setState(() {
      if (_dateRange == DateRangeOption.customRange) {
        _dateRange = DateRangeOption.thisMonth;
        _customStart = null;
        _customEnd = null;
      } else {
        _dateRange = DateRangeOption.customRange;
        _selectedYear = null;
        _customStart ??= DateTime.now().subtract(const Duration(days: 30));
        _customEnd ??= DateTime.now();
      }
    });
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _customStart : _customEnd) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
      } else {
        _customEnd = picked;
      }
    });
  }

  void _showTypePicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Transaction Type'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _type = null);
              Navigator.of(context).pop();
            },
            child: const Text('All'),
          ),
          for (final t in TransactionType.values)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _type = t);
                Navigator.of(context).pop();
              },
              child: Text(t.displayName),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<Category> categories) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Category'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _categoryId = null);
              Navigator.of(context).pop();
            },
            child: const Text('All'),
          ),
          for (final c in categories)
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _categoryId = c.id);
                Navigator.of(context).pop();
              },
              child: Text(c.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _apply(BuildContext context) {
    context.read<TransactionBloc>().add(TransactionFilterChanged(_pendingFilter));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryBloc>().state.categories;
    final categoryName = _categoryId == null
        ? 'All'
        : categories.firstWhere(
            (c) => c.id == _categoryId,
            orElse: () => categories.isNotEmpty
                ? categories.first
                : Category(name: 'All', bucket: BucketType.monthly, userId: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          ).name;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          _SheetHeader(
            title: 'Filters',
            onCancel: () => Navigator.of(context).pop(),
            onSave: () => _apply(context),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const _SectionLabel('Date Range'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickRanges
                          .map((option) => _RangeChip(
                                label: option.label,
                                selected: _dateRange == option,
                                onTap: () => _selectQuickRange(option),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Year'),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    icon: Icons.calendar_today,
                    iconColor: AppColors.primary,
                    label: _dateRange == DateRangeOption.specificYear && _selectedYear != null
                        ? '$_selectedYear'
                        : 'Pick a Year',
                    selected: _dateRange == DateRangeOption.specificYear,
                    onTap: () => _pickYear(context),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Custom Period'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon: Icons.date_range,
                          iconColor: const Color(0xFF00BCD4),
                          label: 'Custom Date Range',
                          selected: _dateRange == DateRangeOption.customRange,
                          onTap: _toggleCustomRange,
                          transparentBackground: true,
                        ),
                        if (_dateRange == DateRangeOption.customRange) ...[
                          const Divider(height: 1, indent: 14, color: AppColors.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text('From', style: AppTextStyles.body)),
                                _Pill(
                                  label: _customStart == null
                                      ? 'Select'
                                      : DateFormat('d MMM yyyy').format(_customStart!),
                                  onTap: () => _pickCustomDate(isStart: true),
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
                                  label: _customEnd == null
                                      ? 'Select'
                                      : DateFormat('d MMM yyyy').format(_customEnd!),
                                  onTap: () => _pickCustomDate(isStart: false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Transaction Type'),
                  const SizedBox(height: 8),
                  _PickerRow(
                    label: 'Select Type',
                    value: _type?.displayName ?? 'All',
                    onTap: () => _showTypePicker(context),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Category'),
                  const SizedBox(height: 8),
                  _PickerRow(
                    label: 'Select Category',
                    value: categoryName,
                    onTap: () => _showCategoryPicker(context, categories),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Preview: $_matchCount matching transaction${_matchCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _SheetHeader({required this.title, required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          CupertinoButton(
            onPressed: onCancel,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontSize: 17)),
          ),
          Expanded(
            child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading2),
          ),
          CupertinoButton(
            onPressed: onSave,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool transparentBackground;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.selected,
    required this.onTap,
    this.transparentBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: selected ? const Color(0xFF00BCD4) : AppColors.textTertiary,
          ),
        ],
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: transparentBackground
          ? content
          : Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: content,
            ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              Text(value, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
            ],
          ),
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
