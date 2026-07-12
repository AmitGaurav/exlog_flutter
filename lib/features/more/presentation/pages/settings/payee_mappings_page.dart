import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../categories/presentation/bloc/category_bloc.dart';
import '../../../domain/entities/payee_mapping.dart';
import '../../bloc/payee_mapping_bloc.dart';
import '../../bloc/payee_mapping_event.dart';
import '../../bloc/payee_mapping_state.dart';
import '../../widgets/add_edit_payee_mapping_sheet.dart';

class PayeeMappingsPage extends StatefulWidget {
  const PayeeMappingsPage({super.key});

  @override
  State<PayeeMappingsPage> createState() => _PayeeMappingsPageState();
}

class _PayeeMappingsPageState extends State<PayeeMappingsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PayeeMappingBloc>().add(const PayeeMappingLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddSheet(BuildContext context) {
    final payeeMappingBloc = context.read<PayeeMappingBloc>();
    final categoryBloc = context.read<CategoryBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: payeeMappingBloc),
          BlocProvider.value(value: categoryBloc),
        ],
        child: const AddEditPayeeMappingSheet(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PayeeMapping mapping) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Payee Mapping'),
        content: Text("Are you sure you want to delete the mapping for '${mapping.payeeName}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PayeeMappingBloc>().add(PayeeMappingDeleteRequested(mapping.id!));
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
        title: const Text('Payee Mappings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openAddSheet(context)),
        ],
      ),
      body: BlocConsumer<PayeeMappingBloc, PayeeMappingState>(
        listenWhen: (prev, cur) => cur.error != null && cur.error != prev.error,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          context.read<PayeeMappingBloc>().add(const PayeeMappingErrorCleared());
        },
        builder: (context, state) {
          if (state.status == PayeeMappingStatus.loading && state.mappings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => context.read<PayeeMappingBloc>().add(PayeeMappingSearchChanged(v)),
                  decoration: InputDecoration(
                    hintText: 'Search payees...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: state.filteredMappings.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: state.filteredMappings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final mapping = state.filteredMappings[index];
                          return _MappingCard(
                            mapping: mapping,
                            onDelete: () => _confirmDelete(context, mapping),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text('No Payee Mappings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          SizedBox(height: 6),
          Text('Tap + to add your first payee mapping', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MappingCard extends StatelessWidget {
  final PayeeMapping mapping;
  final VoidCallback onDelete;
  const _MappingCard({required this.mapping, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(mapping.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mapping.payeeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (mapping.categoryName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(mapping.categoryName!,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                  ],
                  if (mapping.matchCount > 0) ...[
                    const SizedBox(height: 4),
                    Text('Used ${mapping.matchCount} times',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
