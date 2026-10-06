import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../clients/data/models/client_filter.dart';
import '../../data/models/order.dart';
import '../../data/models/orders_query.dart';
import '../../data/models/paginated_orders.dart';
import '../../data/orders_repository.dart';
import 'orders_state.dart';

class OrdersCubit extends SafeCubit<OrdersState> {
  final OrdersRepository _repository;

  final Map<String, List<Order>> _pageCache = {};
  final Map<String, int?> _nextPageCache = {};
  final Map<String, int> _totalCache = {};

  OrdersCubit({required OrdersRepository repository})
    : _repository = repository,
      super(const OrdersState());

  static const int PAGE_SIZE = 10;

  static const String CLIENT_FILTER = 'client';
  static const String PRODUCT_FILTER = 'product';

  String get _cacheKey {
    final OrdersQuery query = _effectiveQuery;
    final List<String> parts = [];

    query.selections.forEach((key, values) {
      final List<String> sorted = values.toList()..sort();
      parts.add('$key=${sorted.join(',')}');
    });

    query.ranges.forEach((key, range) {
      parts.add('$key=${range.from}..${range.to}');
    });

    return '${parts.join('&')}'
        '#sort=${query.sort}'
        '#desc=${query.descending}';
  }

  /// ``get-orders`` has no free-text param: ``client`` and ``product`` are
  /// selects over public ids. The filter catalogue already ships every
  /// eligible id with its name, so a typed term is matched against those
  /// labels and sent as ids -- real server-side filtering, typed as a search.
  OrdersQuery get _effectiveQuery {
    final String term = state.searchQuery.trim();
    if (term.isEmpty) return state.query;

    final Set<String> clients = _matchingValues(CLIENT_FILTER, term);
    final Set<String> products = _matchingValues(PRODUCT_FILTER, term);
    if (clients.isEmpty && products.isEmpty) return state.query;

    OrdersQuery query = state.query;
    if (clients.isNotEmpty) query = _withValues(query, CLIENT_FILTER, clients);
    if (products.isNotEmpty) {
      query = _withValues(query, PRODUCT_FILTER, products);
    }
    return query;
  }

  Set<String> _matchingValues(String filterKey, String term) {
    final String needle = term.toLowerCase();

    for (final ClientFilter filter in state.availableFilters) {
      if (filter.key != filterKey) continue;
      return filter.options
          .where((option) => option.label.toLowerCase().contains(needle))
          .map((option) => option.value)
          .toSet();
    }
    return const {};
  }

  /// A search narrows within whatever the user already picked; it never widens
  /// past an explicit filter selection.
  static OrdersQuery _withValues(
    OrdersQuery query,
    String key,
    Set<String> values,
  ) {
    final Set<String> selected = query.selections[key] ?? const {};
    final Set<String> merged = selected.isEmpty
        ? values
        : selected.intersection(values);

    final Map<String, Set<String>> next = Map.of(query.selections);
    next[key] = merged;
    return query.copyWith(selections: next);
  }

  /// True when a term was typed but matched no client and no product, so the
  /// UI can say so rather than showing an unfiltered list.
  bool get _hasNoSearchMatch {
    final String term = state.searchQuery.trim();
    if (term.isEmpty) return false;
    return _matchingValues(CLIENT_FILTER, term).isEmpty &&
        _matchingValues(PRODUCT_FILTER, term).isEmpty;
  }

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
          status: OrdersStatus.loaded,
          orders: _pageCache[key],
          nextPageNumber: _nextPageCache[key],
          clearNextPage: _nextPageCache[key] == null,
          totalCount: _totalCache[key] ?? 0,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: OrdersStatus.loading, clearError: true));

    try {
      final PaginatedOrders result = await _repository.fetchOrders(
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
          status: OrdersStatus.loaded,
          orders: result.results,
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
      AppLogger.session('failed to load orders: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final int nextPage = state.nextPageNumber!;
    final String key = _cacheKey;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedOrders result = await _repository.fetchOrders(
        page: nextPage,
        pageSize: PAGE_SIZE,
        query: _effectiveQuery,
        rangeParamsByKey: _rangeParams,
      );

      final List<Order> merged = [...state.orders, ...result.results];
      _pageCache[key] = merged;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          orders: merged,
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
      AppLogger.session('failed to load more orders: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> applyQuery(OrdersQuery query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(query: const OrdersQuery()));
    await load();
  }

  void updateSearchQuery(String value) =>
      emit(state.copyWith(searchQuery: value));

  Future<void> submitSearch(String value) async {
    emit(state.copyWith(searchQuery: value.trim()));
    emit(state.copyWith(hasNoSearchMatch: _hasNoSearchMatch));
    if (state.hasNoSearchMatch) return;
    await load();
  }

  Future<void> clearSearch() async {
    emit(state.copyWith(searchQuery: '', hasNoSearchMatch: false));
    await load();
  }

  Future<void> refresh() {
    _pageCache.clear();
    _nextPageCache.clear();
    _totalCache.clear();
    return load(forceRefresh: true);
  }

  void _emitFailure(String message) {
    final String trimmed = message.trim();
    emit(
      state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
