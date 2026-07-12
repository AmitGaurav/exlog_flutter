import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class AddEditCategorySheet extends StatefulWidget {
  final Category? existing;

  const AddEditCategorySheet({super.key, this.existing});

  @override
  State<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<AddEditCategorySheet> {
  final _nameController = TextEditingController();
  late BucketType _selectedBucket;
  late String _selectedIconName;
  late Color _selectedColor;
  bool _requiresComment = false;
  bool _isSaving = false;
  String? _validationError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final cat = widget.existing!;
      _nameController.text = cat.name;
      _selectedBucket = cat.bucket;
      _selectedIconName = cat.iconName ?? kDefaultIconName;
      _selectedColor = colorFromHex(cat.colorHex);
      _requiresComment = cat.requiresComment;
    } else {
      _selectedBucket = BucketType.daily;
      _selectedIconName = kDefaultIconName;
      _selectedColor = kCategoryColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _validationError = 'Please enter a category name.');
      return;
    }
    setState(() {
      _validationError = null;
      _isSaving = true;
    });

    final bloc = context.read<CategoryBloc>();

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        name: name,
        bucket: _selectedBucket,
        requiresComment: _requiresComment,
        iconName: _selectedIconName,
        colorHex: colorToHex(_selectedColor),
        updatedAt: DateTime.now(),
      );
      bloc.add(CategoryUpdateRequested(updated));
    } else {
      final userId = _resolveUserId(context);
      final category = Category.create(
        name: name,
        bucket: _selectedBucket,
        requiresComment: _requiresComment,
        userId: userId,
        iconName: _selectedIconName,
        colorHex: colorToHex(_selectedColor),
      );
      bloc.add(CategoryAddRequested(category));
    }
  }

  String _resolveUserId(BuildContext context) {
    // Pull userId from existing categories list; fallback to empty (backend fills it)
    final cats = context.read<CategoryBloc>().state.categories;
    return cats.isNotEmpty ? cats.first.userId : '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, cur) =>
          _isSaving && (cur.error != prev.error || cur.status == CategoryStatus.success),
      listener: (context, state) {
        if (state.error != null && _isSaving) {
          setState(() {
            _isSaving = false;
            _validationError = state.error;
          });
          context.read<CategoryBloc>().add(const CategoryErrorCleared());
        } else if (state.status == CategoryStatus.success && _isSaving) {
          Navigator.of(context).pop();
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
            _SheetHandle(),
            _SheetHeader(
              title: _isEdit ? 'Edit Category' : 'Add Category',
              onCancel: () => Navigator.of(context).pop(),
              onSave: _isSaving ? null : () => _onSave(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FreeTierBanner(),
                    const SizedBox(height: 20),
                    _SectionLabel('Category Information'),
                    const SizedBox(height: 8),
                    _CategoryInfoCard(
                      nameController: _nameController,
                      validationError: _validationError,
                      selectedBucket: _selectedBucket,
                      requiresComment: _requiresComment,
                      onBucketChanged: (b) => setState(() => _selectedBucket = b),
                      onRequiresCommentChanged: (v) =>
                          setState(() => _requiresComment = v),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Icon'),
                    const SizedBox(height: 8),
                    _IconPicker(
                      selectedIconName: _selectedIconName,
                      selectedColor: _selectedColor,
                      onSelected: (name) =>
                          setState(() => _selectedIconName = name),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Color'),
                    const SizedBox(height: 8),
                    _ColorPicker(
                      selectedColor: _selectedColor,
                      onSelected: (c) => setState(() => _selectedColor = c),
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
                color: onSave == null
                    ? AppColors.textTertiary
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeTierBanner extends StatelessWidget {
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
                  'Free Tier: 15 categories allowed',
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

class _CategoryInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final String? validationError;
  final BucketType selectedBucket;
  final bool requiresComment;
  final ValueChanged<BucketType> onBucketChanged;
  final ValueChanged<bool> onRequiresCommentChanged;

  const _CategoryInfoCard({
    required this.nameController,
    required this.validationError,
    required this.selectedBucket,
    required this.requiresComment,
    required this.onBucketChanged,
    required this.onRequiresCommentChanged,
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
          // Name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Category Name',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                errorText: validationError,
                errorStyle:
                    const TextStyle(fontSize: 12, color: AppColors.expense),
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          // Bucket row
          InkWell(
            onTap: () => _showBucketPicker(context),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Bucket', style: AppTextStyles.body),
                  ),
                  Text(
                    selectedBucket.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more,
                      size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 14, color: AppColors.divider),
          // Requires Comment toggle
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Requires Comment', style: AppTextStyles.body),
                ),
                CupertinoSwitch(
                  value: requiresComment,
                  activeTrackColor: AppColors.primary,
                  onChanged: onRequiresCommentChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBucketPicker(BuildContext context) {
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
                  initialItem: selectedBucket.index,
                ),
                onSelectedItemChanged: (i) =>
                    onBucketChanged(BucketType.values[i]),
                children: BucketType.values
                    .map((b) => Center(
                          child: Text(b.displayName,
                              style: const TextStyle(fontSize: 20)),
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

class _IconPicker extends StatelessWidget {
  final String selectedIconName;
  final Color selectedColor;
  final ValueChanged<String> onSelected;

  const _IconPicker({
    required this.selectedIconName,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final entries = kCategoryIcons.entries.toList();
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final entry = entries[i];
          final isSelected = entry.key == selectedIconName;
          return GestureDetector(
            onTap: () => onSelected(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                entry.value,
                size: 22,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({required this.selectedColor, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: kCategoryColors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final color = kCategoryColors[i];
          final isSelected = selectedColor.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () => onSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: AppColors.textPrimary,
                        width: 2.5,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
