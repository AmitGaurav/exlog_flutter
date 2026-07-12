import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../categories/domain/entities/category.dart' show colorFromHex, colorToHex, kCategoryColors;
import '../../domain/entities/transaction_type_model.dart';
import '../bloc/transaction_type_bloc.dart';
import '../bloc/transaction_type_event.dart';
import '../bloc/transaction_type_state.dart';

class AddEditTransactionTypeSheet extends StatefulWidget {
  final TransactionTypeModel? existing;
  const AddEditTransactionTypeSheet({super.key, this.existing});

  @override
  State<AddEditTransactionTypeSheet> createState() => _AddEditTransactionTypeSheetState();
}

class _AddEditTransactionTypeSheetState extends State<AddEditTransactionTypeSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _displayNameController;
  late String _selectedIcon;
  late Color _selectedColor;
  late int _sortOrder;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;
  bool get _isDefault => widget.existing?.isDefault ?? false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _displayNameController = TextEditingController(text: existing?.displayName ?? '');
    _selectedIcon = existing?.icon ?? kDefaultTransactionTypeIcon;
    _selectedColor = colorFromHex(existing?.colorHex ?? '#007AFF');
    _sortOrder = existing?.sortOrder ?? 99;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '_');
    final displayName = _displayNameController.text.trim();
    if (name.isEmpty || displayName.isEmpty) return;

    setState(() => _isSaving = true);
    final userId = sl<FirebaseAuth>().currentUser?.uid ?? '';
    final existing = widget.existing;
    final now = DateTime.now();

    if (existing == null) {
      final type = TransactionTypeModel(
        userId: userId,
        name: name,
        displayName: displayName,
        icon: _selectedIcon,
        colorHex: colorToHex(_selectedColor),
        sortOrder: _sortOrder,
        createdAt: now,
        updatedAt: now,
      );
      context.read<TransactionTypeBloc>().add(TransactionTypeAddRequested(type));
    } else {
      final type = existing.copyWith(
        name: _isDefault ? existing.name : name,
        displayName: displayName,
        icon: _selectedIcon,
        colorHex: colorToHex(_selectedColor),
        sortOrder: _sortOrder,
      );
      context.read<TransactionTypeBloc>().add(TransactionTypeUpdateRequested(type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty && _displayNameController.text.trim().isNotEmpty;

    return BlocListener<TransactionTypeBloc, TransactionTypeState>(
      listenWhen: (prev, cur) => _isSaving && (cur.error != prev.error || cur.status == TransactionTypeStatus.success),
      listener: (context, state) {
        if (state.error != null && _isSaving) {
          setState(() => _isSaving = false);
        } else if (state.status == TransactionTypeStatus.success && _isSaving) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    Expanded(
                      child: Text(_isEditing ? 'Edit Type' : 'New Type',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: _isSaving || !canSave ? null : () => _save(context),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Container(
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            enabled: !_isDefault,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(hintText: 'Name (unique)', border: InputBorder.none),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          TextField(
                            controller: _displayNameController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(hintText: 'Display Name', border: InputBorder.none),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          Row(
                            children: [
                              const Text('Sort Order', style: TextStyle(fontSize: 15)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _sortOrder > 1 ? () => setState(() => _sortOrder--) : null,
                              ),
                              Text('$_sortOrder'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() => _sortOrder++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_isDefault)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text('Name cannot be changed for default types',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    const SizedBox(height: 20),
                    const Text('ICON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _IconGrid(selectedIcon: _selectedIcon, onSelected: (v) => setState(() => _selectedIcon = v)),
                    const SizedBox(height: 20),
                    const Text('COLOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _ColorSwatchPicker(selectedColor: _selectedColor, onSelected: (c) => setState(() => _selectedColor = c)),
                    const SizedBox(height: 20),
                    const Text('PREVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(kTransactionTypeIcons[_selectedIcon] ?? Icons.circle, color: _selectedColor, size: 26),
                          const SizedBox(width: 14),
                          Text(
                            _displayNameController.text.isEmpty ? 'Display Name' : _displayNameController.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final String selectedIcon;
  final ValueChanged<String> onSelected;
  const _IconGrid({required this.selectedIcon, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final entries = kTransactionTypeIcons.entries.toList();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((entry) {
        final isSelected = entry.key == selectedIcon;
        return GestureDetector(
          onTap: () => onSelected(entry.key),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
            ),
            alignment: Alignment.center,
            child: Icon(entry.value, color: isSelected ? AppColors.primary : AppColors.textPrimary),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorSwatchPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelected;
  const _ColorSwatchPicker({required this.selectedColor, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kCategoryColors.map((color) {
        final isSelected = colorToHex(color) == colorToHex(selectedColor);
        return GestureDetector(
          onTap: () => onSelected(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: AppColors.textPrimary, width: 2) : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }
}
