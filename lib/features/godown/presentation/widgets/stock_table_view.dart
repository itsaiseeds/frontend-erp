import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../products/presentation/widgets/products_search_bar.dart';
import '../../data/models/stock_table_query.dart';
import 'stock_filter_sheet.dart';
import 'stock_table.dart';
import 'stock_table_toolbar.dart';

/// The stock table page shared by bag and packet stock: status icon, search and
/// filter on one row, then a real two-column table. Kept as one widget so both
/// screens cannot drift apart again.
class StockTableView extends StatelessWidget {
  final bool isComplete;
  final List<StockTableEntry> entries;
  final StockTableQuery query;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<StockTableQuery> onFilterApplied;
  final VoidCallback onOpenFillStock;
  final Future<void> Function() onRefresh;

  const StockTableView({
    super.key,
    required this.isComplete,
    required this.entries,
    required this.query,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterApplied,
    required this.onOpenFillStock,
    required this.onRefresh,
  });

  Future<void> _openFilters(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final StockTableQuery? applied = await StockFilterSheet.show(
      context,
      query: query,
    );
    if (applied != null) onFilterApplied(applied);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.MD16,
            AppSpacing.SMD12,
            AppSpacing.MD16,
            0,
          ),
          child: Row(
            children: [
              StockCountStatusIcon(isComplete: isComplete),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: ProductsSearchBar(
                  controller: searchController,
                  hintText: AppStrings.STOCK_SEARCH_HINT,
                  onChanged: onSearchChanged,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  onClear: onClearSearch,
                ),
              ),
              const SizedBox(width: AppSpacing.SM8),
              StockFilterButton(
                activeCount: query.activeCount,
                onTap: () => _openFilters(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.PRIMARY,
            onRefresh: onRefresh,
            child: entries.isEmpty
                ? _NoMatches(onRefresh: onRefresh)
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.MD16,
                      0,
                      AppSpacing.MD16,
                      AppSizes.ORDER_LIST_BOTTOM_INSET,
                    ),
                    children: [
                      StockTable(entries: entries, onRowTap: onOpenFillStock),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _NoMatches extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _NoMatches({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: AppSizes.ICON_XXL,
                  color: AppColors.TEXT_DISABLED,
                ),
                const SizedBox(height: AppSpacing.MD16),
                Text(
                  AppStrings.STOCK_NO_SEARCH_MATCH,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
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
