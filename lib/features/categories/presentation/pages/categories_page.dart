import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../widgets/add_edit_category_sheet.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const CategoryLoadRequested());
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: const AddEditCategorySheet(),
      ),
    );
  }

  void _openEditSheet(BuildContext context, Category category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: AddEditCategorySheet(existing: category),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content:
            Text('Delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<CategoryBloc>()
                  .add(CategoryDeleteRequested(category.id!));
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
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listenWhen: (prev, cur) => cur.error != null && cur.error != prev.error,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.expense,
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              if (state.status == CategoryStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.categories.isEmpty)
                SliverFillRemaining(child: _EmptyState(
                  onAddTap: () => _openAddSheet(context),
                ))
              else
                _buildCategoryList(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.backgroundGray,
      pinned: true,
      expandedHeight: 96,
      scrolledUnderElevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, size: 28, color: AppColors.textPrimary),
          onPressed: () => _openAddSheet(context),
        ),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 12),
        title: Text(
          'Categories',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, CategoryState state) {
    final grouped = state.categoriesByBucket;
    final buckets = BucketType.values
        .where((b) => grouped.containsKey(b))
        .toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, sectionIndex) {
          final bucket = buckets[sectionIndex];
          final cats = grouped[bucket]!;
          return _BucketSection(
            bucket: bucket,
            categories: cats,
            onTap: (cat) => _openEditSheet(context, cat),
            onDelete: (cat) => _confirmDelete(context, cat),
          );
        },
        childCount: buckets.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 72,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No categories yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first category',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: const Icon(Icons.add_circle, size: 20),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bucket section header + category cards
// ─────────────────────────────────────────────────────────────────────────────

class _BucketSection extends StatelessWidget {
  final BucketType bucket;
  final List<Category> categories;
  final ValueChanged<Category> onTap;
  final ValueChanged<Category> onDelete;

  const _BucketSection({
    required this.bucket,
    required this.categories,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BucketHeader(bucket: bucket),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < categories.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 58,
                      color: AppColors.divider,
                    ),
                  _CategoryTile(
                    category: categories[i],
                    onTap: () => onTap(categories[i]),
                    onDelete: () => onDelete(categories[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketHeader extends StatelessWidget {
  final BucketType bucket;
  const _BucketHeader({required this.bucket});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(bucket.icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          bucket.displayName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = colorFromHex(category.colorHex);
    return Dismissible(
      key: ValueKey(category.id ?? category.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // deletion is handled in confirmDelete dialog
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconDataFromName(category.iconName),
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: AppTextStyles.body),
                    const SizedBox(height: 2),
                    Text(
                      category.bucket.displayName,
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ),
              if (category.requiresComment)
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
