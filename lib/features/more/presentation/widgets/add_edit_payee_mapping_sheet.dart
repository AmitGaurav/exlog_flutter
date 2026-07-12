import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../categories/domain/entities/category.dart' show Category;
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/entities/payee_mapping.dart';
import '../bloc/payee_mapping_bloc.dart';
import '../bloc/payee_mapping_event.dart';
import '../bloc/payee_mapping_state.dart';

class AddEditPayeeMappingSheet extends StatefulWidget {
  const AddEditPayeeMappingSheet({super.key});

  @override
  State<AddEditPayeeMappingSheet> createState() => _AddEditPayeeMappingSheetState();
}

class _AddEditPayeeMappingSheetState extends State<AddEditPayeeMappingSheet> {
  final _payeeController = TextEditingController();
  Category? _selectedCategory;
  bool _isSaving = false;

  @override
  void dispose() {
    _payeeController.dispose();
    super.dispose();
  }

  void _showCategoryPicker(List<Category> categories) {
    final initialIndex = _selectedCategory == null
        ? 0
        : categories.indexWhere((c) => c.id == _selectedCategory!.id).clamp(0, categories.length - 1);
    if (categories.isNotEmpty) {
      setState(() => _selectedCategory ??= categories[initialIndex]);
    }
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
                onSelectedItemChanged: (i) => setState(() => _selectedCategory = categories[i]),
                children: categories.map((c) => Center(child: Text(c.name, style: const TextStyle(fontSize: 20)))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final payeeName = _payeeController.text.trim();
    if (payeeName.isEmpty || _selectedCategory == null) return;

    setState(() => _isSaving = true);
    final userId = sl<FirebaseAuth>().currentUser?.uid ?? '';
    final mapping = PayeeMapping.create(
      payeeName: payeeName,
      categoryId: _selectedCategory!.id!,
      categoryName: _selectedCategory!.name,
      userId: userId,
    );
    context.read<PayeeMappingBloc>().add(PayeeMappingAddRequested(mapping));
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryBloc>().state.categories;

    return BlocListener<PayeeMappingBloc, PayeeMappingState>(
      listenWhen: (prev, cur) => _isSaving && (cur.error != prev.error || cur.status == PayeeMappingStatus.success),
      listener: (context, state) {
        if (state.error != null && _isSaving) {
          setState(() => _isSaving = false);
        } else if (state.status == PayeeMappingStatus.success && _isSaving) {
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
                  const Expanded(
                    child: Text('Add Mapping',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: _isSaving || _payeeController.text.trim().isEmpty || _selectedCategory == null
                        ? null
                        : () => _save(context),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        TextField(
                          controller: _payeeController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Payee Name',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        InkWell(
                          onTap: () => _showCategoryPicker(categories),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Row(
                              children: [
                                const Text('Category', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
                                const Spacer(),
                                Text(_selectedCategory?.name ?? 'Select Category',
                                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                                const SizedBox(width: 4),
                                const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
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
    );
  }
}
