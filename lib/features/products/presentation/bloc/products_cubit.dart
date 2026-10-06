import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../clients/data/models/client_filter.dart';
import '../../data/models/cart_line.dart';
import '../../data/models/paginated_products.dart';
import '../../data/models/product_packaging.dart';
import '../../data/models/products_query.dart';
import '../../data/products_repository.dart';
import 'products_state.dart';

class ProductsCubit extends SafeCubit<ProductsState> {
  final ProductsRepository _repository;

  final Map<String, List<ProductPackaging>> _pageCache = {};
  final Map<String, int?> _nextPageCache = {};
  final Map<String, int> _totalCache = {};

  ProductsCubit({required ProductsRepository repository})
    : _repository = repository,
      super(const ProductsState());

  static const int PAGE_SIZE = 10;

  String get _cacheKey {
    final ProductsQuery query = _effectiveQuery;
    final List<String> parts = [];

    query.selections.forEach((key, values) {
      final List<String> sorted = values.toList()..sort();
      parts.add('$key=${sorted.join(',')}');
    });

    query.ranges.forEach((key, range) {
      parts.add('$key=${range.from}..${range.to}');
    });

    return '${parts.join('&')}'
        '#name=${query.name}'
        '#sort=${query.sort}'
        '#desc=${query.descending}';
  }

  ProductsQuery get _effectiveQuery =>
      state.query.copyWith(name: state.searchQuery);

  Map<String, List<String>> get _rangeParams {
    final Map<String, List<String>> params = {};
    for (final ClientFilter filter in state.availableFilters) {
      if (filter.params.isNotEmpty) params[filter.key] = filter.params;
    }
    return params;
  }

  Future<void> load({bool forceRefresh = false}) async {
    final String key = _cacheKey;

    if (!forceRefresh && _pageCache.containsKey(key)) {
      emit(
        state.copyWith(
          status: ProductsStatus.loaded,
          products: _pageCache[key],
          nextPageNumber: _nextPageCache[key],
          clearNextPage: _nextPageCache[key] == null,
          totalCount: _totalCache[key] ?? 0,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ProductsStatus.loading, clearError: true));

    try {
      final PaginatedProducts result = await _repository.fetchCatalogue(
        page: 1,
        pageSize: PAGE_SIZE,
        query: _effectiveQuery,
        rangeParamsByKey: _rangeParams,
      );

      _pageCache[key] = result.results;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          status: ProductsStatus.loaded,
          products: result.results,
          availableFilters: result.availableFilters.isEmpty
              ? state.availableFilters
              : result.availableFilters,
          availableSorts: result.availableSorts.isEmpty
              ? state.availableSorts
              : result.availableSorts,
          page: 1,
          totalCount: result.totalCount,
          nextPageNumber: result.nextPageNumber,
          clearNextPage: result.nextPageNumber == null,
        ),
      );
    } on ApiException catch (e) {
      _emitFailure(e.message);
    } catch (e) {
      AppLogger.session('failed to load products: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final int nextPage = state.nextPageNumber!;
    final String key = _cacheKey;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedProducts result = await _repository.fetchCatalogue(
        page: nextPage,
        pageSize: PAGE_SIZE,
        query: _effectiveQuery,
        rangeParamsByKey: _rangeParams,
      );

      final List<ProductPackaging> merged = [
        ...state.products,
        ...result.results,
      ];
      _pageCache[key] = merged;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          products: merged,
          page: nextPage,
          totalCount: result.totalCount,
          nextPageNumber: result.nextPageNumber,
          clearNextPage: result.nextPageNumber == null,
          isLoadingMore: false,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.message));
    } catch (e) {
      AppLogger.session('failed to load more products: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> applyQuery(ProductsQuery query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(query: const ProductsQuery()));
    await load();
  }

  void updateSearchQuery(String value) =>
      emit(state.copyWith(searchQuery: value));

  Future<void> submitSearch(String value) async {
    emit(state.copyWith(searchQuery: value.trim()));
    await load();
  }

  Future<void> clearSearch() async {
    emit(state.copyWith(searchQuery: ''));
    await load();
  }

  Future<void> refresh() {
    _pageCache.clear();
    _nextPageCache.clear();
    _totalCache.clear();
    return load(forceRefresh: true);
  }

  void addToCart(ProductPackaging packaging) {
    final Map<String, CartLine> next = Map.of(state.cart);
    final CartLine? existing = next[packaging.publicId];

    next[packaging.publicId] = existing == null
        ? CartLine(packaging: packaging)
        : existing.copyWith(quantity: existing.quantity + 1);

    emit(state.copyWith(cart: next));
  }

  void removeFromCart(ProductPackaging packaging) {
    final Map<String, CartLine> next = Map.of(state.cart);
    final CartLine? existing = next[packaging.publicId];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      next.remove(packaging.publicId);
    } else {
      next[packaging.publicId] = existing.copyWith(
        quantity: existing.quantity - 1,
      );
    }

    emit(state.copyWith(cart: next));
  }

  void removeLine(String packagingPublicId) {
    final Map<String, CartLine> next = Map.of(state.cart);
    if (next.remove(packagingPublicId) == null) return;
    emit(state.copyWith(cart: next));
  }

  void clearCart() => emit(state.copyWith(cart: const {}));

  void _emitFailure(String message) {
    final String trimmed = message.trim();
    emit(
      state.copyWith(
        status: ProductsStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
