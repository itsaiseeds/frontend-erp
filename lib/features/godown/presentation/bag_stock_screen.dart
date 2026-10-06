import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/godown_repository.dart';
import '../data/models/bag_stock_draft_line.dart';
import '../data/models/stock_table_query.dart';
import 'bloc/bag_stock_cubit.dart';
import 'bloc/bag_stock_state.dart';
import 'fast_mode_screen.dart';
import 'widgets/fast_mode_row.dart';
import 'widgets/godown_card_shimmer.dart';
import 'widgets/stock_table.dart';
import 'widgets/stock_table_view.dart';

class BagStockScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const BagStockScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BagStockCubit>(
      create: (context) => BagStockCubit(
        repository: GodownRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: _BagStockView(onMenuTap: onMenuTap),
    );
  }
}

class _BagStockView extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const _BagStockView({this.onMenuTap});

  @override
  State<_BagStockView> createState() => _BagStockViewState();
}

class _BagStockViewState extends State<_BagStockView> {
  final TextEditingController _searchController = TextEditingController();
  StockTableQuery _query = const StockTableQuery();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(StockTableQuery query) => setState(() => _query = query);

  Future<void> _openFastMode(BagStockCubit cubit, BagStockState state) async {
    final List<BagStockDraftLine> lines = state.lines;
    await FastModeScreen.push(
      context,
      title: AppStrings.BAG_STOCK_TITLE,
      unitLabel: AppStrings.STOCK_BAGS_UNIT,
      rows: [
        for (final BagStockDraftLine line in lines)
          FastModeRow(
            key: line.packagingPublicId,
            title: line.packaging.product.name,
            subtitle:
                '${line.packaging.packets} ${AppStrings.STOCK_PACKETS_UNIT} × '
                '${line.packaging.packetWeight} kg',
            imageUrl: line.packaging.product.imageUrl,
            draftCount: line.draftCount,
          ),
      ],
      onCountChanged: cubit.setDraftCount,
      onSubmit: () => _submit(cubit),
    );
    if (mounted) setState(() {});
  }

  Future<bool> _submit(BagStockCubit cubit) async {
    final bool ok = await cubit.submitDraft();
    if (!mounted) return ok;
    if (ok) {
      ToastUtils.showSuccess(context, AppStrings.STOCK_SUBMIT_SUCCESS);
    } else if (cubit.state.errorMessage != null) {
      ToastUtils.showServerError(context, cubit.state.errorMessage!);
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BagStockCubit, BagStockState>(
      builder: (context, state) {
        final BagStockCubit cubit = context.read<BagStockCubit>();

        return DismissKeyboard(
          child: Scaffold(
            backgroundColor: AppColors.BACKGROUND,
            appBar: AppBar(
              backgroundColor: AppColors.SURFACE,
              surfaceTintColor: AppColors.TRANSPARENT,
              elevation: 0,
              leading: widget.onMenuTap == null
                  ? null
                  : IconButton(
                      onPressed: widget.onMenuTap,
                      icon: const Icon(Icons.menu_rounded),
                    ),
              title: Text(
                AppStrings.BAG_STOCK_TITLE,
                style: AppTypography.titleMedium,
              ),
              actions: [
                TextButton(
                  onPressed: state.lines.isEmpty
                      ? null
                      : () => _openFastMode(cubit, state),
                  child: Text(
                    AppStrings.STOCK_FILL_STOCK,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.PRIMARY,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.XS6),
              ],
            ),
            body: _Body(
              state: state,
              cubit: cubit,
              query: _query,
              searchController: _searchController,
              onQueryChanged: _setQuery,
              onOpenFillStock: () => _openFastMode(cubit, state),
            ),
            // No submit button here on purpose: saving now happens only through
            // the confirmed Update on the Fill Stock review page, so there is
            // a single guarded path to the server.
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final BagStockState state;
  final BagStockCubit cubit;
  final StockTableQuery query;
  final TextEditingController searchController;
  final ValueChanged<StockTableQuery> onQueryChanged;
  final VoidCallback onOpenFillStock;

  const _Body({
    required this.state,
    required this.cubit,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
    required this.onOpenFillStock,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == BagStockStatus.loading && state.packagings.isEmpty) {
      // Table skeleton, not the card one: this page renders a table once
      // loaded, and horizontal padding has to match `StockTableView`'s list so
      // the header does not jump sideways when the rows arrive.
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
        child: GodownTableShimmer(),
      );
    }

    if (state.status == BagStockStatus.failure && state.packagings.isEmpty) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: AppStrings.SOMETHING_WENT_WRONG,
        body: state.errorMessage ?? '',
        onRefresh: cubit.load,
      );
    }

    if (state.packagings.isEmpty) {
      return _Message(
        icon: Icons.inventory_2_outlined,
        title: AppStrings.STOCK_NO_PACKAGINGS_TITLE,
        body: AppStrings.STOCK_NO_PACKAGINGS_BODY,
        onRefresh: cubit.load,
      );
    }

    return StockTableView(
      isComplete: state.isComplete,
      query: query,
      searchController: searchController,
      entries: [
        for (final BagStockDraftLine line in _filter(state.lines))
          StockTableEntry(
            title: line.packaging.label,
            subtitle: line.packaging.product.name,
            available: line.position?.available,
          ),
      ],
      onSearchChanged: (value) => onQueryChanged(query.copyWith(search: value)),
      onClearSearch: () {
        searchController.clear();
        onQueryChanged(query.copyWith(search: ''));
      },
      onFilterApplied: onQueryChanged,
      onOpenFillStock: onOpenFillStock,
      onRefresh: cubit.load,
    );
  }

  List<BagStockDraftLine> _filter(List<BagStockDraftLine> lines) {
    final List<BagStockDraftLine> matched = [
      for (final BagStockDraftLine line in lines)
        if (query.filter.matches(hasPosition: line.position != null) &&
            stockRowMatches(
              query: query.search,
              title: line.packaging.label,
              subtitle: line.packaging.product.name,
            ))
          line,
    ];

    matched.sort(
      (BagStockDraftLine a, BagStockDraftLine b) => compareStockRows(
        query.sort,
        title: a.packaging.label,
        available: a.position?.available,
        otherTitle: b.packaging.label,
        otherAvailable: b.position?.available,
      ),
    );
    return matched;
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function() onRefresh;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.XXXL80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppSizes.ICON_XXL,
                  color: AppColors.TEXT_DISABLED,
                ),
                const SizedBox(height: AppSpacing.MD16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium,
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.SM8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.XL32,
                    ),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.TEXT_SECONDARY,
                      ),
                    ),
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
