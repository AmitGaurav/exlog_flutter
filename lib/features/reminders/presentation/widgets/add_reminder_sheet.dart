import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/app_config_service.dart';
import '../../../categories/domain/entities/category.dart' show Category;
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';

class AddReminderSheet extends StatefulWidget {
  const AddReminderSheet({super.key});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _dueDate = DateTime.now();
  RepeatType _repeatType = RepeatType.monthly;
  int _customDaysInterval = 30;
  Category? _selectedCategory;
  bool _notificationEnabled = true;
  int _notificationDaysBefore = 3;

  bool _isSaving = false;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    setState(() {
      _titleError = title.isEmpty ? 'Title is required' : null;
    });
    if (_titleError != null) return;

    final amount = amountText.isEmpty ? null : double.tryParse(amountText);

    setState(() => _isSaving = true);

    final reminder = Reminder.create(
      title: title,
      amount: amount,
      dueDate: _dueDate,
      repeatType: _repeatType,
      customDaysInterval: _repeatType == RepeatType.custom ? _customDaysInterval : null,
      notificationEnabled: _notificationEnabled,
      notificationDaysBefore: _notificationDaysBefore,
      categoryId: _selectedCategory?.id,
      categoryName: _selectedCategory?.name,
      userId: sl<FirebaseAuth>().currentUser?.uid ?? '',
    );
    context.read<ReminderBloc>().add(ReminderAddRequested(reminder));
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _showRepeatPicker() {
    showCupertinoModalPopup<void>(
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
                scrollController: FixedExtentScrollController(initialItem: _repeatType.index),
                onSelectedItemChanged: (i) => setState(() => _repeatType = RepeatType.values[i]),
                children: RepeatType.values
                    .map((t) => Center(child: Text(t.displayName, style: const TextStyle(fontSize: 20))))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(List<Category> categories) {
    final items = <Category?>[null, ...categories];
    final initialIndex = _selectedCategory == null
        ? 0
        : items.indexWhere((c) => c?.id == _selectedCategory!.id).clamp(0, items.length - 1);
    showCupertinoModalPopup<void>(
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
                scrollController: FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (i) => setState(() => _selectedCategory = items[i]),
                children: items
                    .map((c) => Center(
                          child: Text(c?.name ?? 'None', style: const TextStyle(fontSize: 20)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryBloc>().state.categories;

    return BlocListener<ReminderBloc, ReminderState>(
      listenWhen: (prev, cur) =>
          _isSaving && (cur.error != prev.error || cur.status == ReminderStatus.success),
      listener: (context, state) {
        if (state.error != null && _isSaving) {
          setState(() {
            _isSaving = false;
            _titleError = state.error;
          });
          context.read<ReminderBloc>().add(const ReminderErrorCleared());
        } else if (state.status == ReminderStatus.success && _isSaving) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
      },
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
              title: 'Add Reminder',
              onCancel: () => Navigator.of(context).pop(),
              onSave: _isSaving ? null : () => _onSave(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: sl<AppConfigService>().freeForAll,
                      builder: (context, freeForAll, _) => freeForAll
                          ? const SizedBox.shrink()
                          : const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [_FreeTierBanner(), SizedBox(height: 20)],
                            ),
                    ),
                    const _SectionLabel('Reminder Details'),
                    const SizedBox(height: 8),
                    _ReminderDetailsCard(
                      titleController: _titleController,
                      amountController: _amountController,
                      titleError: _titleError,
                      dueDate: _dueDate,
                      repeatType: _repeatType,
                      customDaysInterval: _customDaysInterval,
                      onDueDateTap: _pickDueDate,
                      onRepeatTap: _showRepeatPicker,
                      onCustomDaysChanged: (v) => setState(() => _customDaysInterval = v),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Category'),
                    const SizedBox(height: 8),
                    _PickerRow(
                      label: 'Select Category (Optional)',
                      value: _selectedCategory?.name ?? 'None',
                      onTap: categories.isEmpty ? null : () => _showCategoryPicker(categories),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Notification'),
                    const SizedBox(height: 8),
                    _NotificationCard(
                      enabled: _notificationEnabled,
                      daysBefore: _notificationDaysBefore,
                      onEnabledChanged: (v) => setState(() => _notificationEnabled = v),
                      onDaysBeforeChanged: (v) => setState(() => _notificationDaysBefore = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _FreeTierBanner extends StatelessWidget {
  const _FreeTierBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Free Tier: 5 active reminders allowed',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    '★ Upgrade for Unlimited',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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

class _ReminderDetailsCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final String? titleError;
  final DateTime dueDate;
  final RepeatType repeatType;
  final int customDaysInterval;
  final VoidCallback onDueDateTap;
  final VoidCallback onRepeatTap;
  final ValueChanged<int> onCustomDaysChanged;

  const _ReminderDetailsCard({
    required this.titleController,
    required this.amountController,
    required this.titleError,
    required this.dueDate,
    required this.repeatType,
    required this.customDaysInterval,
    required this.onDueDateTap,
    required this.onRepeatTap,
    required this.onCustomDaysChanged,
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
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                errorText: titleError,
                errorStyle: const TextStyle(fontSize: 12, color: AppColors.expense),
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Amount (Optional)',
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text('Due Date', style: AppTextStyles.body)),
                _Pill(label: DateFormat('d MMM yyyy').format(dueDate), onTap: onDueDateTap),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          InkWell(
            onTap: onRepeatTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text('Repeat', style: AppTextStyles.body)),
                  Text(
                    repeatType.displayName,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (repeatType == RepeatType.custom) ...[
            const Divider(height: 1, indent: 14, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Every $customDaysInterval Days', style: AppTextStyles.body)),
                  _Stepper(
                    value: customDaysInterval,
                    min: 1,
                    onChanged: onCustomDaysChanged,
                  ),
                ],
              ),
            ),
          ],
        ],
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

class _PickerRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

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

class _NotificationCard extends StatelessWidget {
  final bool enabled;
  final int daysBefore;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onDaysBeforeChanged;

  const _NotificationCard({
    required this.enabled,
    required this.daysBefore,
    required this.onEnabledChanged,
    required this.onDaysBeforeChanged,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Enable Notification', style: AppTextStyles.body)),
                CupertinoSwitch(
                  value: enabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1, indent: 14, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Notify $daysBefore days before', style: AppTextStyles.body),
                  ),
                  _Stepper(value: daysBefore, min: 0, onChanged: onDaysBeforeChanged),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.value, required this.min, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Container(width: 1, height: 20, color: AppColors.divider),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(value + 1),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
