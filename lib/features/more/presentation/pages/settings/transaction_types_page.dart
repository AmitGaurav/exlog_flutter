import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../categories/domain/entities/category.dart' show colorFromHex;
import '../../../domain/entities/transaction_type_model.dart';
import '../../bloc/transaction_type_bloc.dart';
import '../../bloc/transaction_type_event.dart';
import '../../bloc/transaction_type_state.dart';
import '../../widgets/add_edit_transaction_type_sheet.dart';

class TransactionTypesPage extends StatefulWidget {
  const TransactionTypesPage({super.key});

  @override
  State<TransactionTypesPage> createState() => _TransactionTypesPageState();
}

class _TransactionTypesPageState extends State<TransactionTypesPage> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionTypeBloc>().add(const TransactionTypeLoadRequested());
  }

  void _openSheet(BuildContext context, {TransactionTypeModel? existing}) {
    final bloc = context.read<TransactionTypeBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AddEditTransactionTypeSheet(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionTypeModel type) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction Type'),
        content: Text("Are you sure you want to delete '${type.displayName}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TransactionTypeBloc>().add(TransactionTypeDeleteRequested(type.id!));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        title: const Text('Transaction Types', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openSheet(context)),
        ],
      ),
      body: BlocConsumer<TransactionTypeBloc, TransactionTypeState>(
        listenWhen: (prev, cur) => cur.error != null && cur.error != prev.error,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        builder: (context, state) {
          if (state.status == TransactionTypeStatus.loading && state.types.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              for (final type in state.types)
                Dismissible(
                  key: ValueKey(type.id),
                  direction: type.isDefault ? DismissDirection.none : DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    _confirmDelete(context, type);
                    return false;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openSheet(context, existing: type),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(kTransactionTypeIcons[type.icon] ?? Icons.circle,
                                  color: colorFromHex(type.colorHex), size: 26),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(type.displayName, style: const TextStyle(fontSize: 15)),
                                    Text(type.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (type.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Default',
                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Default types cannot be deleted. You can create custom types for your specific needs.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
