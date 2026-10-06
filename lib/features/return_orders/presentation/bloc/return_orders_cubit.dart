import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../clients/data/models/client_filter.dart';
import '../../data/models/paginated_return_orders.dart';
import '../../data/models/return_order.dart';
import '../../data/models/return_orders_query.dart';
import '../../data/return_orders_repository.dart';
import 'return_orders_state.dart';

class ReturnOrdersCubit extends SafeCubit<ReturnOrdersState> {
  final ReturnOrdersRepository _repository;

  final Map<String, List<ReturnOrder>> _pageCache = {};
  final Map<String, int?> _nextPageCache = {};
  final Map<String, int> _totalCache = {};

  ReturnOrdersCubit({required ReturnOrdersRepository repository})
    : _repository = repository,
      super(const ReturnOrdersState());

  static const int PAGE_SIZE = 10;

  String get _cacheKey {
    final ReturnOrdersQuery query = state.query;
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
          status: ReturnOrdersStatus.loaded,
          returnOrders: _pageCache[key],
          nextPageNumber: _nextPageCache[key],
          clearNextPage: _nextPageCache[key] == null,
          totalCount: _totalCache[key] ?? 0,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ReturnOrdersStatus.loading, clearError: true));

    try {
      final PaginatedReturnOrders result = await _repository.fetchReturnOrders(
        page: 1,
        pageSize: PAGE_SIZE,
        query: state.query,
        rangeParamsByKey: _rangeParams,
      );

      _pageCache[key] = result.results;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          status: ReturnOrdersStatus.loaded,
          returnOrders: result.results,
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
      AppLogger.session('failed to load return orders: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final int nextPage = state.nextPageNumber!;
    final String key = _cacheKey;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedReturnOrders result = await _repository.fetchReturnOrders(
        page: nextPage,
        pageSize: PAGE_SIZE,
        query: state.query,
        rangeParamsByKey: _rangeParams,
      );

      final List<ReturnOrder> merged = [...state.returnOrders, ...result.results];
      _pageCache[key] = merged;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          returnOrders: merged,
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
      AppLogger.session('failed to load more return orders: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> applyQuery(ReturnOrdersQuery query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(query: const ReturnOrdersQuery()));
    await load();
  }

  /// The endpoint has no free-text param, so a term only narrows what is
  /// already loaded -- there is nothing to re-request.
  void updateSearchQuery(String value) =>
      emit(state.copyWith(searchQuery: value));

  Future<void> submitSearch(String value) async {
    emit(state.copyWith(searchQuery: value.trim()));
    if (state.status == ReturnOrdersStatus.initial ||
        state.status == ReturnOrdersStatus.failure) {
      await load();
    }
  }

  Future<void> clearSearch() async {
    emit(state.copyWith(searchQuery: ''));
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
        status: ReturnOrdersStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
