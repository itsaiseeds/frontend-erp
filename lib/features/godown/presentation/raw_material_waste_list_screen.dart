import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../clients/data/models/clients_query.dart';
import '../../clients/presentation/widgets/clients_filter_sheet.dart';
import '../../products/presentation/widgets/products_search_bar.dart';
import '../data/godown_repository.dart';
import '../data/models/raw_material_waste.dart';
import 'bloc/raw_material_waste_cubit.dart';
import 'bloc/raw_material_waste_state.dart';
import 'raw_material_waste_detail_screen.dart';
import 'raw_material_waste_form_screen.dart';
import 'widgets/godown_card.dart';
import 'widgets/godown_card_shimmer.dart';

class RawMaterialWasteListScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const RawMaterialWasteListScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RawMaterialWasteCubit>(
      create: (context) => RawMaterialWasteCubit(
        repository: GodownRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: _RawMaterialWasteView(onMenuTap: onMenuTap),
    );
  }
}

class _RawMaterialWasteView extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const _RawMaterialWasteView({this.onMenuTap});

  @override
  State<_RawMaterialWasteView> createState() => _RawMaterialWasteViewState();
}

class _RawMaterialWasteViewState extends State<_RawMaterialWasteView> {
  static const double _loadMoreThreshold = 320;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double remaining =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining <= _loadMoreThreshold) {
      context.read<RawMaterialWasteCubit>().loadMore();
    }
  }

  Future<void> _record() async {
    final RawMaterialWasteCubit cubit = context.read<RawMaterialWasteCubit>();
    await RawMaterialWasteFormScreen.push(context, cubit: cubit);
  }

  Future<void> _openFilters() async {
    final RawMaterialWasteCubit cubit = context.read<RawMaterialWasteCubit>();
    final RawMaterialWasteState state = cubit.state;

    final ClientsQuery? applied = await ClientsFilterSheet.show(
      context,
      filters: state.availableFilters,
      sorts: state.availableSorts,
      query: state.query,
    );
    if (applied == null) return;
    await cubit.applyQuery(applied);
  }

  Future<void> _openDetail(RawMaterialWaste waste) async {
    final RawMaterialWasteCubit cubit = context.read<RawMaterialWasteCubit>();
    await RawMaterialWasteDetailScreen.push(context, waste: waste, cubit: cubit);
  }

  List<RawMaterialWaste> _visible(RawMaterialWasteState state) {
    final String needle = state.searchQuery.trim();
    if (needle.isEmpty) return state.wastes;
    return state.wastes.where((waste) => waste.matchesSearch(needle)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RawMaterialWasteCubit, RawMaterialWasteState>(
      builder: (context, state) {
        final List<RawMaterialWaste> visible = _visible(state);
        final bool hasLocalSearch = state.searchQuery.trim().isNotEmpty;

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
                AppStrings.WASTE_LIST_TITLE,
                style: AppTypography.titleMedium,
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _record,
              backgroundColor: AppColors.PRIMARY,
              foregroundColor: AppColors.TEXT_ON_PRIMARY,
              elevation: 0,
              highlightElevation: 0,
              tooltip: AppStrings.WASTE_ADD_TITLE,
              child: const Icon(Icons.add_rounded, size: AppSizes.ICON_XL),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.MD16,
                    AppSpacing.SMD12,
                    AppSpacing.MD16,
                    AppSpacing.SM8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ProductsSearchBar(
                          controller: _searchController,
                          hintText: AppStrings.WASTE_SEARCH_HINT,
                          onChanged: context
                              .read<RawMaterialWasteCubit>()
                              .updateSearchQuery,
                          onSubmitted: (value) =>
                              FocusScope.of(context).unfocus(),
                          onClear: () {
                            _searchController.clear();
                            context
                                .read<RawMaterialWasteCubit>()
                                .updateSearchQuery('');
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.SM8),
                      _FilterButton(
                        activeCount: state.query.activeCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                ),
                if (!hasLocalSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.MD16,
                      0,
                      AppSpacing.MD16,
                      AppSpacing.SM8,
                    ),
                    child: _ResultSummary(count: state.totalCount, state: state),
                  ),
                Expanded(
                  child: _Body(
                    state: state,
                    visible: visible,
                    hasLocalSearch: hasLocalSearch,
                    scrollController: _scrollController,
                    onRefresh: context.read<RawMaterialWasteCubit>().refresh,
                    onTap: _openDetail,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final int count;
  final RawMaterialWasteState state;

  const _ResultSummary({required this.count, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status != RawMaterialWasteStatusState.loaded) {
      return const SizedBox.shrink();
    }

    final String noun = count == 1
        ? AppStrings.WASTE_RECORD_COUNT_ONE
        : AppStrings.WASTE_RECORD_COUNT_MANY;

    return Row(
      children: [
        Flexible(
          child: Text(
            '$count $noun',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
        if (state.query.hasFilters) ...[
          const SizedBox(width: AppSpacing.SMD12),
          GestureDetector(
            onTap: context.read<RawMaterialWasteCubit>().clearFilters,
            behavior: HitTestBehavior.opaque,
            child: Text(
              AppStrings.CLIENTS_CLEAR_ALL,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.PRIMARY,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeCount > 0;

    return Material(
      color: isActive ? AppColors.PRIMARY : AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.CLIENT_FILTER_CONTROL,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.SMD12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? AppColors.PRIMARY : AppColors.BORDER,
            ),
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: AppSizes.ICON_MD,
                color: isActive
                    ? AppColors.TEXT_ON_PRIMARY
                    : AppColors.TEXT_SECONDARY,
              ),
              if (isActive) ...[
                const SizedBox(width: AppSpacing.XS6),
                Text(
                  '$activeCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final RawMaterialWasteState state;
  final List<RawMaterialWaste> visible;
  final bool hasLocalSearch;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(RawMaterialWaste) onTap;

  const _Body({
    required this.state,
    required this.visible,
    required this.hasLocalSearch,
    required this.scrollController,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == RawMaterialWasteStatusState.loading && state.wastes.isEmpty) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.SMD12),
        child: GodownCardShimmer(),
      );
    }

    if (state.status == RawMaterialWasteStatusState.failure && state.wastes.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.error_outline_rounded,
        title: AppStrings.SOMETHING_WENT_WRONG,
        body: state.errorMessage ?? '',
      );
    }

    if (state.wastes.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.delete_sweep_outlined,
        title: AppStrings.WASTE_EMPTY_TITLE,
        body: AppStrings.WASTE_EMPTY_BODY,
      );
    }

    if (visible.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.search_off_rounded,
        title: AppStrings.INWARD_NO_SEARCH_MATCH,
        body: '',
      );
    }

    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.SMD12,
          AppSpacing.SM8,
          AppSpacing.SMD12,
          AppSizes.ORDER_LIST_BOTTOM_INSET,
        ),
        itemCount:
            visible.length + (!hasLocalSearch && state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.SMD12),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return const GodownCardShimmerTile();
          }

          final RawMaterialWaste waste = visible[index];
          return GodownCard(
            icon: Icons.delete_sweep_outlined,
            title: waste.product.name,
            codeLabel: waste.publicId,
            tagLabel: waste.isFromRejectedLot
                ? AppStrings.WASTE_FROM_REJECTED_LOT_LABEL.replaceAll(
                    '%s',
                    waste.inwardRawMaterial!.lotNo,
                  )
                : null,
            tagColor: waste.isFromRejectedLot ? AppColors.WARNING : null,
            onTap: () => onTap(waste),
            stats: [
              GodownCardStat(
                label: AppStrings.WASTE_FIELD_QUANTITY_KG,
                value: '${waste.quantityKg} ${AppStrings.KG_LABEL}',
                valueColor: AppColors.PRIMARY,
              ),
              GodownCardStat(
                label: AppStrings.WASTE_FIELD_CREATED_AT,
                value: DateFormatter.dayShort(waste.createdAt),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RefreshableMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;
  final String body;

  const _RefreshableMessage({
    required this.onRefresh,
    required this.icon,
    required this.title,
    required this.body,
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
                Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
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
