import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../clients/presentation/widgets/clients_filter_sheet.dart';
import '../data/models/product_packaging.dart';
import '../data/models/products_query.dart';
import '../data/products_repository.dart';
import 'bloc/products_cubit.dart';
import 'bloc/products_state.dart';
import 'product_detail_screen.dart';
import 'checkout_screen.dart';
import 'widgets/cart_bar.dart';
import 'widgets/product_card.dart';
import 'widgets/products_search_bar.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductsCubit>(
      create: (context) => ProductsCubit(
        repository: ProductsRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  static const int _gridColumns = 2;
  static const double _cardExtent = 238.0;
  static const double _loadMoreThreshold = 320;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      context.read<ProductsCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final ProductsCubit cubit = context.read<ProductsCubit>();
    final ProductsState state = cubit.state;

    final ProductsQuery? applied = await ClientsFilterSheet.show(
      context,
      filters: state.availableFilters,
      sorts: state.availableSorts,
      query: state.query.asClientsQuery(),
    ).then((result) => result?.asProductsQuery());

    if (applied == null) return;
    await cubit.applyQuery(applied);
  }

  void _openDetail(ProductPackaging packaging) {
    final ProductsCubit cubit = context.read<ProductsCubit>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProductsCubit>.value(
          value: cubit,
          child: ProductDetailScreen(packaging: packaging),
        ),
      ),
    );
  }

  void _openCheckout() {
    final ProductsCubit cubit = context.read<ProductsCubit>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProductsCubit>.value(
          value: cubit,
          child: const CheckoutScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final ProductsCubit cubit = context.read<ProductsCubit>();

        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          body: Stack(
            children: [
              DismissKeyboard(
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
                    if (state.status == ProductsStatus.loaded)
                      _ResultBar(
                        count: state.totalCount,
                        hasFilters: state.query.hasFilters,
                        onClear: cubit.clearFilters,
                      ),
                    Expanded(
                      child: _Body(
                        state: state,
                        scrollController: _scrollController,
                        gridColumns: _gridColumns,
                        cardExtent: _cardExtent,
                        onRefresh: cubit.refresh,
                        onTapProduct: _openDetail,
                        onAdd: cubit.addToCart,
                        onRemove: cubit.removeFromCart,
                      ),
                    ),
                  ],
                ),
              ),
              // Floating, so an empty cart reserves no space under the grid.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: CartBar(
                    lines: state.cartLines,
                    itemCount: state.cartItemCount,
                    total: state.cartTotal,
                    onTap: _openCheckout,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ProductsState state;
  final ScrollController scrollController;
  final int gridColumns;
  final double cardExtent;
  final Future<void> Function() onRefresh;
  final void Function(ProductPackaging) onTapProduct;
  final void Function(ProductPackaging) onAdd;
  final void Function(ProductPackaging) onRemove;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.gridColumns,
    required this.cardExtent,
    required this.onRefresh,
    required this.onTapProduct,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.products.isEmpty) {
      return RefreshIndicator(
        color: AppColors.PRIMARY,
        onRefresh: onRefresh,
        child: _ProductGridShimmer(
          gridColumns: gridColumns,
          cardExtent: cardExtent,
        ),
      );
    }

    if (state.status == ProductsStatus.failure) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.error_outline_rounded,
          title: AppStrings.PRODUCTS_ERROR_TITLE,
          body: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }

    if (state.products.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: const _Message(
          icon: Icons.search_off_rounded,
          title: AppStrings.PRODUCTS_EMPTY_TITLE,
          body: AppStrings.PRODUCTS_EMPTY_BODY,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: GridView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.SMD12,
          AppSpacing.SM8,
          AppSpacing.SMD12,
          AppSizes.CLIENT_LIST_BOTTOM_INSET,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          crossAxisSpacing: AppSpacing.SM8,
          mainAxisSpacing: AppSpacing.SM8,
          mainAxisExtent: cardExtent,
        ),
        itemCount: state.products.length,
        itemBuilder: (context, index) {
          final ProductPackaging packaging = state.products[index];
          return ProductCard(
            packaging: packaging,
            quantity: state.quantityOf(packaging.publicId),
            onTap: () => onTapProduct(packaging),
            onAdd: () => onAdd(packaging),
            onRemove: () => onRemove(packaging),
          );
        },
      ),
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  static const int _placeholderCount = 6;

  final int gridColumns;
  final double cardExtent;

  const _ProductGridShimmer({
    required this.gridColumns,
    required this.cardExtent,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SM8,
        AppSpacing.SMD12,
        AppSizes.CLIENT_LIST_BOTTOM_INSET,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: AppSpacing.SM8,
        mainAxisSpacing: AppSpacing.SM8,
        mainAxisExtent: cardExtent,
      ),
      itemCount: _placeholderCount,
      itemBuilder: (context, index) => Container(
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

class _ResultBar extends StatelessWidget {
  final int count;
  final bool hasFilters;
  final VoidCallback onClear;

  const _ResultBar({
    required this.count,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count ${count == 1 ? AppStrings.CART_ITEM : AppStrings.CART_ITEMS}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          if (hasFilters)
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
      ),
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
