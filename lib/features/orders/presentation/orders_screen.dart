import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../clients/presentation/widgets/clients_filter_sheet.dart';
import '../../products/presentation/widgets/products_search_bar.dart';
import '../data/models/order.dart';
import '../data/models/orders_query.dart';
import '../data/orders_repository.dart';
import 'bloc/orders_cubit.dart';
import 'bloc/orders_state.dart';
import 'order_detail_screen.dart';
import 'widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (context) => OrdersCubit(
        repository: OrdersRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
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
      context.read<OrdersCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final OrdersCubit cubit = context.read<OrdersCubit>();
    final OrdersState state = cubit.state;

    final OrdersQuery? applied = await ClientsFilterSheet.show(
      context,
      filters: state.availableFilters,
      sorts: state.availableSorts,
      query: state.query.asClientsQuery(),
    ).then((result) => result?.asOrdersQuery());

    if (applied == null) return;
    await cubit.applyQuery(applied);
  }

  void _openDetail(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final OrdersCubit cubit = context.read<OrdersCubit>();

        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          body: DismissKeyboard(
            child: Column(
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
                          hintText: AppStrings.ORDERS_SEARCH_HINT,
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
                        state.status == OrdersStatus.loaded &&
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
                    onTapOrder: _openDetail,
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

class _Body extends StatelessWidget {
  final OrdersState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(Order) onTapOrder;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onTapOrder,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.orders.isEmpty) {
      return RefreshIndicator(
        color: AppColors.PRIMARY,
        onRefresh: onRefresh,
        child: const _OrderListShimmer(),
      );
    }

    if (state.hasNoSearchMatch) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: const _Message(
          icon: Icons.search_off_rounded,
          title: AppStrings.ORDERS_NO_MATCH_TITLE,
          body: AppStrings.ORDERS_NO_MATCH_BODY,
        ),
      );
    }

    if (state.status == OrdersStatus.failure) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.error_outline_rounded,
          title: AppStrings.ORDERS_ERROR_TITLE,
          body: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }

    if (state.orders.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: const _Message(
          icon: Icons.receipt_long_outlined,
          title: AppStrings.ORDERS_EMPTY_TITLE,
          body: AppStrings.ORDERS_EMPTY_BODY,
        ),
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
        itemCount: state.orders.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.SMD12),
        itemBuilder: (context, index) {
          if (index >= state.orders.length) return const _LoadMoreIndicator();

          final Order order = state.orders[index];
          return OrderCard(order: order, onTap: () => onTapOrder(order));
        },
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.MD16),
      child: Center(
        child: SizedBox(
          width: AppSizes.ICON_LG,
          height: AppSizes.ICON_LG,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.BORDER_MEDIUM,
            color: AppColors.PRIMARY,
          ),
        ),
      ),
    );
  }
}

class _OrderListShimmer extends StatelessWidget {
  static const int _placeholderCount = 4;
  static const double _cardHeight = 164.0;

  const _OrderListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SM8,
        AppSpacing.SMD12,
        AppSizes.ORDER_LIST_BOTTOM_INSET,
      ),
      itemCount: _placeholderCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.SMD12),
      itemBuilder: (context, index) => Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: AppColors.SURFACE,
          border: Border.all(color: AppColors.BORDER),
          borderRadius: BorderRadius.circular(AppRadius.XL),
        ),
      ),
    );
  }
}

class _RefreshableMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _RefreshableMessage({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
            const SizedBox(height: AppSpacing.SMD12),
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.XS6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ],
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
        ? AppStrings.ORDERS_COUNT_ONE
        : AppStrings.ORDERS_COUNT_MANY;

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
        if (hasFilters) ...[
          const SizedBox(width: AppSpacing.SMD12),
          GestureDetector(
            onTap: onClear,
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
