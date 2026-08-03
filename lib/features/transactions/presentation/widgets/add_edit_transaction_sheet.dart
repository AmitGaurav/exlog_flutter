import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/validators.dart';
import '../../../categories/domain/entities/category.dart' show Category;
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';

class AddEditTransactionSheet extends StatefulWidget {
  final Transaction? existing;

  const AddEditTransactionSheet({super.key, this.existing});

  @override
  State<AddEditTransactionSheet> createState() => _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState extends State<AddEditTransactionSheet> {
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _notesController = TextEditingController();
  final _notesFieldKey = GlobalKey();

  late TransactionType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  Category? _selectedCategory;

  bool _isSaving = false;
  String? _amountError;
  String? _payeeError;
  String? _categoryError;
  String? _notesError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final categories = context.read<CategoryBloc>().state.categories;
    if (_isEdit) {
      final tx = widget.existing!;
      _amountController.text = _formatAmount(tx.amount);
      _payeeController.text = tx.payee;
      _notesController.text = tx.notes ?? '';
      _selectedType = tx.type;
      _selectedDate = tx.timestamp;
      _selectedTime = TimeOfDay.fromDateTime(tx.timestamp);
      if (tx.categoryId != null) {
        for (final c in categories) {
          if (c.id == tx.categoryId) {
            _selectedCategory = c;
            break;
          }
        }
      }
    } else {
      _selectedType = TransactionType.expense;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // The sheet's own SingleChildScrollView doesn't reliably auto-scroll a
  // newly-focused field above the keyboard here (likely due to the nested
  // Flexible/mainAxisSize.min layout confusing Flutter's default
  // showOnScreen heuristic), so the Notes field — the one most likely to
  // end up hidden behind the keyboard — gets an explicit nudge once the
  // keyboard animation has settled.
  void _scrollNotesIntoView() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final ctx = _notesFieldKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatAmount(double amount) =>
      amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toString();

  void _onSave(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim());
    final payee = _payeeController.text.trim();
    final notes = _notesController.text.trim();

    setState(() {
      _amountError = Validators.amount(_amountController.text);
      _payeeError = payee.isEmpty ? 'Payee is required' : null;
      _categoryError = _selectedCategory == null ? 'Please select a category' : null;
      _notesError = (_selectedCategory?.requiresComment == true && notes.isEmpty)
          ? 'Comment is required for this category'
          : null;
    });

    if (_amountError != null ||
        _payeeError != null ||
        _categoryError != null ||
        _notesError != null) {
      return;
    }

    setState(() => _isSaving = true);

    final timestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final bloc = context.read<TransactionBloc>();

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        amount: amount,
        payee: payee,
        type: _selectedType,
        timestamp: timestamp,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        bucket: _selectedCategory!.bucket,
        notes: notes.isEmpty ? null : notes,
        updatedAt: DateTime.now(),
      );
      bloc.add(TransactionUpdateRequested(updated));
    } else {
      final transaction = Transaction.create(
        amount: amount!,
        payee: payee,
        type: _selectedType,
        timestamp: timestamp,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        bucket: _selectedCategory!.bucket,
        notes: notes.isEmpty ? null : notes,
        userId: sl<FirebaseAuth>().currentUser?.uid ?? '',
        isManual: true,
      );
      bloc.add(TransactionAddRequested(transaction));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryBloc>().state.categories;

    return BlocListener<TransactionBloc, TransactionState>(
      listenWhen: (prev, cur) =>
          _isSaving && (cur.error != prev.error || cur.status == TransactionStatus.success),
      listener: (context, state) {
        if (state.error != null && _isSaving) {
          setState(() {
            _isSaving = false;
            _amountError = state.error;
          });
          context.read<TransactionBloc>().add(const TransactionErrorCleared());
        } else if (state.status == TransactionStatus.success && _isSaving) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
      },
      child: Padding(
        // The modal route's own keyboard-avoidance padding isn't reliably
        // shrinking this sheet's layout (confirmed: Scrollable.ensureVisible
        // finds nothing to scroll because the viewport still thinks it has
        // the full un-shrunk height), so the keyboard inset is applied here
        // explicitly instead of relying on that.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            _SheetHeader(
              title: _isEdit ? 'Edit Transaction' : 'Add Transaction',
              onCancel: () => Navigator.of(context).pop(),
              onSave: _isSaving ? null : () => _onSave(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const _SectionLabel('Transaction Details'),
                    const SizedBox(height: 8),
                    _TransactionDetailsCard(
                      amountController: _amountController,
                      payeeController: _payeeController,
                      autofocusAmount: !_isEdit,
                      amountError: _amountError,
                      payeeError: _payeeError,
                      selectedType: _selectedType,
                      selectedDate: _selectedDate,
                      selectedTime: _selectedTime,
                      onTypeChanged: (t) => setState(() => _selectedType = t),
                      onDateChanged: (d) => setState(() => _selectedDate = d),
                      onTimeChanged: (t) => setState(() => _selectedTime = t),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Category'),
                    const SizedBox(height: 8),
                    _CategoryRow(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      error: _categoryError,
                      onSelected: (c) => setState(() => _selectedCategory = c),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const _SectionLabel('Notes'),
                        if (_selectedCategory?.requiresComment == true)
                          const Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Text(
                              '*',
                              style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _NotesCard(
                      key: _notesFieldKey,
                      controller: _notesController,
                      onTap: _scrollNotesIntoView,
                    ),
                    if (_notesError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _notesError!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFFF9500)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
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
  final VoidCallback? onSave;

  const _SheetHeader({
    required this.title,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          CupertinoButton(
            onPressed: onCancel,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primary, fontSize: 17),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
          ),
          CupertinoButton(
            onPressed: onSave,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: onSave == null ? AppColors.textTertiary : AppColors.primary,
              ),
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

class _TransactionDetailsCard extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController payeeController;
  final bool autofocusAmount;
  final String? amountError;
  final String? payeeError;
  final TransactionType selectedType;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _TransactionDetailsCard({
    required this.amountController,
    required this.payeeController,
    required this.autofocusAmount,
    required this.amountError,
    required this.payeeError,
    required this.selectedType,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: amountController,
              autofocus: autofocusAmount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Amount',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                errorText: amountError,
                errorStyle: const TextStyle(fontSize: 12, color: AppColors.expense),
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: payeeController,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Payee',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                errorText: payeeError,
                errorStyle: const TextStyle(fontSize: 12, color: AppColors.expense),
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          InkWell(
            onTap: () => _showTypePicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text('Type', style: AppTextStyles.body)),
                  Icon(_typeIcon(selectedType), size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    selectedType.displayName,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('Date', style: AppTextStyles.body)),
                _Pill(
                  label: DateFormat('d MMM yyyy').format(selectedDate),
                  onTap: () => _pickDate(context),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: selectedTime.format(context),
                  onTap: () => _pickTime(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
      case TransactionType.cashWithdrawal:
        return Icons.arrow_downward;
      case TransactionType.credit:
        return Icons.arrow_upward;
      case TransactionType.selfTransfer:
        return Icons.swap_horiz;
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) onTimeChanged(picked);
  }

  void _showTypePicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedType.index,
                ),
                onSelectedItemChanged: (i) => onTypeChanged(TransactionType.values[i]),
                children: TransactionType.values
                    .map((t) => Center(
                          child: Text(t.displayName, style: const TextStyle(fontSize: 20)),
                        ))
                    .toList(),
              ),
            ),
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
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final String? error;
  final ValueChanged<Category> onSelected;

  const _CategoryRow({
    required this.categories,
    required this.selectedCategory,
    required this.error,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: categories.isEmpty ? null : () => _showCategoryPicker(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text('Select Category', style: AppTextStyles.body)),
                  Text(
                    selectedCategory?.name ?? 'None',
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(fontSize: 13, color: Color(0xFFFF9500))),
        ],
      ],
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final initialIndex = selectedCategory == null
        ? 0
        : categories.indexWhere((c) => c.id == selectedCategory!.id).clamp(0, categories.length - 1);
    // CupertinoPicker only invokes onSelectedItemChanged when the user scrolls
    // to a different index, so the initially-highlighted item must be applied
    // up front — otherwise tapping Done without scrolling leaves it unselected.
    onSelected(categories[initialIndex]);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44,
                scrollController: FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (i) => onSelected(categories[i]),
                children: categories
                    .map((c) => Center(
                          child: Text(c.name, style: const TextStyle(fontSize: 20)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTap;
  const _NotesCard({super.key, required this.controller, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        onTap: onTap,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Add a note...',
          hintStyle: TextStyle(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
