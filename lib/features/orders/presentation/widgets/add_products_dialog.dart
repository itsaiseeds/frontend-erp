import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../../products/data/models/cart_line.dart';
import '../../../products/data/models/product_packaging.dart';
import '../../../products/data/models/products_query.dart';
import '../../../products/data/products_repository.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../products/presentation/widgets/products_search_bar.dart';

/// Full-screen "add products" picker for the edit-order flow: the same
/// catalogue grid/cards a salesperson browses from when booking a fresh
/// order (`ProductsScreen`/`ProductCard`), opened over the order being
/// edited so items can be added without leaving it. Starts pre-selected with
/// whatever is already on the order, and hands back the full edited
/// selection on Done rather than diffing -- simplest contract for the
/// caller (`EditOrderCubit.setLines`).
class AddProductsDialog extends StatelessWidget {
  final List<CartLine> initialLines;

  const AddProductsDialog({super.key, required this.initialLines});

  static Future<List<CartLine>?> show(
    BuildContext context, {
    required List<CartLine> initialLines,
  }) {
    return showDialog<List<CartLine>>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => AddProductsDialog(initialLines: initialLines),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.BACKGROUND,
      child: _AddProductsView(initialLines: initialLines),
    );
  }
}

class _AddProductsView extends StatefulWidget {
  final List<CartLine> initialLines;

  const _AddProductsView({required this.initialLines});

  @override
  State<_AddProductsView> createState() => _AddProductsViewState();
}

class _AddProductsViewState extends State<_AddProductsView> {
  static const int _pageSize = 20;
  static const int _gridColumns = 2;
  static const double _cardExtent = 238.0;
  static const double _loadMoreThreshold = 320;

  late final ProductsRepository _repository = ProductsRepository(
    apiClient: context.read<ApiClient>(),
  );

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Keyed by packaging public id, seeded from the order's current lines so
  /// everything already on the order shows its real quantity immediately,
  /// even before that product's page of the catalogue has loaded.
  late Map<String, CartLine> _selected = {
    for (final line in widget.initialLines) line.packaging.publicId: line,
  };

  List<ProductPackaging> _products = [];
  int? _nextPage;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || _nextPage == null) {
      return;
    }
    final double remaining =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining <= _loadMoreThreshold) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _repository.fetchCatalogue(
        page: 1,
        pageSize: _pageSize,
        query: ProductsQuery(name: _query),
        rangeParamsByKey: const {},
      );
      if (!mounted) return;
      setState(() {
        _products = result.results;
        _nextPage = result.nextPageNumber;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.PRODUCTS_ERROR_TITLE;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final int? page = _nextPage;
    if (page == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final result = await _repository.fetchCatalogue(
        page: page,
        pageSize: _pageSize,
        query: ProductsQuery(name: _query),
        rangeParamsByKey: const {},
      );
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...result.results];
        _nextPage = result.nextPageNumber;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _load();
  }

  void _add(ProductPackaging packaging) {
    setState(() {
      final CartLine? existing = _selected[packaging.publicId];
      _selected = {
        ..._selected,
        packaging.publicId: existing == null
            ? CartLine(packaging: packaging)
            : existing.copyWith(quantity: existing.quantity + 1),
      };
    });
  }

  void _remove(ProductPackaging packaging) {
    final CartLine? existing = _selected[packaging.publicId];
    if (existing == null) return;

    setState(() {
      if (existing.quantity <= 1) {
        _selected = {..._selected}..remove(packaging.publicId);
      } else {
        _selected = {
          ..._selected,
          packaging.publicId: existing.copyWith(
            quantity: existing.quantity - 1,
          ),
        };
      }
    });
  }

  void _set(ProductPackaging packaging, int quantity) {
    if (quantity < 1) return;

    setState(() {
      final CartLine? existing = _selected[packaging.publicId];
      _selected = {
        ..._selected,
        packaging.publicId: existing == null
            ? CartLine(packaging: packaging, quantity: quantity)
            : existing.copyWith(quantity: quantity),
      };
    });
  }

  int _quantityOf(String publicId) => _selected[publicId]?.quantity ?? 0;

  @override
  Widget build(BuildContext context) {
    final List<CartLine> selectedLines = _selected.values.toList();
    final num total = selectedLines.fold<num>(
      0,
      (sum, line) => sum + line.lineTotal,
    );

    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUND,
        appBar: AppBar(
          backgroundColor: AppColors.SURFACE,
          surfaceTintColor: AppColors.TRANSPARENT,
          elevation: 0,
          leadingWidth: AppSpacing.XL32 + AppSpacing.SM8,
          titleSpacing: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              size: AppSizes.ICON_LG,
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
          title: Text(
            AppStrings.ADD_PRODUCTS_TITLE,
            style: AppTypography.titleMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedLines),
              child: Text(
                AppStrings.DONE,
                style: AppTypography.labelStrong.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.SM8),
          ],
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
              child: ProductsSearchBar(
                controller: _searchController,
                hintText: AppStrings.PRODUCTS_SEARCH_HINT,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ),
            if (selectedLines.isNotEmpty)
              _SelectionBar(count: selectedLines.length, total: total),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.PRIMARY),
      );
    }

    if (_error != null) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: AppStrings.PRODUCTS_ERROR_TITLE,
        body: _error!,
      );
    }

    if (_products.isEmpty) {
      return const _Message(
        icon: Icons.search_off_rounded,
        title: AppStrings.PRODUCTS_EMPTY_TITLE,
        body: AppStrings.PRODUCTS_EMPTY_BODY,
      );
    }

    return GridView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SM8,
        AppSpacing.SMD12,
        AppSizes.CLIENT_LIST_BOTTOM_INSET,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumns,
        crossAxisSpacing: AppSpacing.SM8,
        mainAxisSpacing: AppSpacing.SM8,
        mainAxisExtent: _cardExtent,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final ProductPackaging packaging = _products[index];
        return ProductCard(
          packaging: packaging,
          quantity: _quantityOf(packaging.publicId),
          onTap: () {},
          onAdd: () => _add(packaging),
          onRemove: () => _remove(packaging),
          onSet: (quantity) => _set(packaging, quantity),
        );
      },
    );
  }
}

/// A slim sticky summary between the search bar and the grid -- how many
/// products are selected and what they add up to, so Done's effect is never
/// a surprise after scrolling past items picked earlier.
class _SelectionBar extends StatelessWidget {
  final int count;
  final num total;

  const _SelectionBar({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        0,
        AppSpacing.MD16,
        AppSpacing.SM8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SMD12,
        vertical: AppSpacing.SM8,
      ),
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: AppSizes.ICON_MD,
            color: AppColors.PRIMARY,
          ),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(
            child: Text(
              '$count ${count == 1 ? AppStrings.CART_ITEM : AppStrings.CART_ITEMS} ${AppStrings.ADD_PRODUCTS_SELECTED}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_PRIMARY,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.rupees(total),
            style: AppTypography.labelStrong.copyWith(
              color: AppColors.PRIMARY,
            ),
          ),
        ],
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
