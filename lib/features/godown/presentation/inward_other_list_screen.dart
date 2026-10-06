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
import '../data/models/inward_other_material.dart';
import 'bloc/inward_other_cubit.dart';
import 'bloc/inward_other_state.dart';
import 'inward_other_detail_screen.dart';
import 'inward_other_form_screen.dart';
import 'widgets/godown_card.dart';
import 'widgets/godown_card_shimmer.dart';

class InwardOtherListScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const InwardOtherListScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InwardOtherCubit>(
      create: (context) => InwardOtherCubit(
        repository: GodownRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: _InwardOtherView(onMenuTap: onMenuTap),
    );
  }
}

class _InwardOtherView extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const _InwardOtherView({this.onMenuTap});

  @override
  State<_InwardOtherView> createState() => _InwardOtherViewState();
}

class _InwardOtherViewState extends State<_InwardOtherView> {
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
      context.read<InwardOtherCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final InwardOtherCubit cubit = context.read<InwardOtherCubit>();
    final InwardOtherState state = cubit.state;

    final ClientsQuery? applied = await ClientsFilterSheet.show(
      context,
      filters: state.availableFilters,
      sorts: state.availableSorts,
      query: state.query,
    );
    if (applied == null) return;
    await cubit.applyQuery(applied);
  }

  Future<void> _book() async {
    final InwardOtherCubit cubit = context.read<InwardOtherCubit>();
    final bool? booked = await InwardOtherFormScreen.push(
      context,
      cubit: cubit,
    );
    if (booked ?? false) await cubit.refresh();
  }

  Future<void> _openDetail(InwardOtherMaterial lot) async {
    final InwardOtherCubit cubit = context.read<InwardOtherCubit>();
    await InwardOtherDetailScreen.push(context, lot: lot, cubit: cubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InwardOtherCubit, InwardOtherState>(
      builder: (context, state) {
        final InwardOtherCubit cubit = context.read<InwardOtherCubit>();

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
                AppStrings.INWARD_OTHER_MATERIALS_TITLE,
                style: AppTypography.titleMedium,
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _book,
              backgroundColor: AppColors.PRIMARY,
              foregroundColor: AppColors.TEXT_ON_PRIMARY,
              elevation: 0,
              highlightElevation: 0,
              tooltip: AppStrings.INWARD_BOOK_OTHER,
              child: const Icon(Icons.add_rounded, size: AppSizes.ICON_XL),
            ),
            body: Column(
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
                          hintText: AppStrings.INWARD_OTHER_SEARCH_HINT,
                          onChanged: cubit.updateSearchQuery,
                          onSubmitted: (value) {
                            FocusScope.of(context).unfocus();
                            cubit.submitSearch(value);
                          },
                          onClear: () {
                            _searchController.clear();
                            cubit.clearSearch();
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.MD16,
                  ),
                  child: _ResultSummary(
                    count: state.totalCount,
                    isLoaded:
                        state.status == InwardOtherStatusState.loaded &&
                        !state.hasNoSearchMatch,
                    hasFilters: state.query.hasFilters,
                    onClear: cubit.clearFilters,
                  ),
                ),
                Expanded(
                  child: _Body(
                    state: state,
                    scrollController: _scrollController,
                    onRefresh: cubit.refresh,
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

class _ResultSummary extends StatelessWidget {
  final int count;
  final bool isLoaded;
  final bool hasFilters;
  final VoidCallback onClear;

  const _ResultSummary({
    required this.count,
    required this.isLoaded,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) return const SizedBox.shrink();

    final String noun = count == 1
        ? AppStrings.INWARD_LOT_COUNT_ONE
        : AppStrings.INWARD_LOT_COUNT_MANY;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.SM8),
      child: Row(
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
          if (hasFilters) ...[
            const SizedBox(width: AppSpacing.SMD12),
            GestureDetector(
              onTap: onClear,
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
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final InwardOtherState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(InwardOtherMaterial) onTap;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == InwardOtherStatusState.loading && state.lots.isEmpty) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.SMD12),
        child: GodownCardShimmer(),
      );
    }

    if (state.status == InwardOtherStatusState.failure && state.lots.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.error_outline_rounded,
        title: AppStrings.SOMETHING_WENT_WRONG,
        body: state.errorMessage ?? '',
      );
    }

    if (state.hasNoSearchMatch) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.search_off_rounded,
        title: AppStrings.INWARD_NO_SEARCH_MATCH,
        body: '',
      );
    }

    if (state.lots.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.inventory_2_outlined,
        title: AppStrings.INWARD_EMPTY_TITLE,
        body: AppStrings.INWARD_EMPTY_BODY,
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
        itemCount: state.lots.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.SMD12),
        itemBuilder: (context, index) {
          if (index >= state.lots.length) {
            return const GodownCardShimmerTile();
          }

          final InwardOtherMaterial lot = state.lots[index];
          return GodownCard(
            icon: Icons.move_to_inbox_outlined,
            title: lot.productName,
            tagLabel: lot.materialTypeName,
            codeLabel: lot.party.name,
            onTap: () => onTap(lot),
            stats: [
              GodownCardStat(
                label: AppStrings.INWARD_FIELD_QUANTITY,
                value: lot.quantity,
                valueColor: AppColors.PRIMARY,
              ),
              GodownCardStat(
                label: AppStrings.INWARD_FIELD_EFFECTIVE_DATE,
                value: DateFormatter.dayShort(lot.effectiveDate),
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
