import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/clients_repository.dart';
import '../../data/models/client.dart';
import '../../data/models/client_filter.dart';
import '../../data/models/client_status.dart';
import '../../data/models/clients_query.dart';
import '../../data/models/paginated_clients.dart';
import 'clients_state.dart';

class ClientsCubit extends SafeCubit<ClientsState> {
  final ClientsRepository _repository;

  final Map<String, List<Client>> _pageCache = {};
  final Map<String, int?> _nextPageCache = {};
  final Map<String, int> _totalCache = {};

  ClientsCubit({required ClientsRepository repository})
    : _repository = repository,
      super(const ClientsState(statusView: ClientStatus.verified));

  static const String STATUS_FILTER_KEY = 'status';

  static const int PAGE_SIZE = 10;

  String get _cacheKey {
    final ClientsQuery query = _effectiveQuery;
    final List<String> parts = [];
    query.selections.forEach((key, values) {
      final List<String> sorted = values.toList()..sort();
      parts.add('$key=${sorted.join('|')}');
    });
    query.ranges.forEach((key, range) {
      parts.add(
        '$key=${range.from?.toIso8601String()}~${range.to?.toIso8601String()}',
      );
    });
    parts.sort();
    return '${parts.join('&')}'
        '#name=${query.companyName}'
        '#address=${query.address}'
        '#sort=${query.sort}'
        '#desc=${query.descending}';
  }

  ClientsQuery get _effectiveQuery {
    final ClientStatus? view = state.statusView;
    if (view == null) return state.query;
    return state.query.withSelection(STATUS_FILTER_KEY, {
      ClientStatusX.rawOf(view),
    });
  }

  Map<String, List<String>> get _rangeParams {
    final Map<String, List<String>> params = {};
    for (final ClientFilter filter in state.availableFilters) {
      if (filter.kind == FilterKind.datetimeRange) {
        params[filter.key] = [filter.lowerBoundParam, filter.upperBoundParam];
      }
    }
    return params;
  }

  Future<void> load({bool forceRefresh = false}) async {
    final String key = _cacheKey;

    if (!forceRefresh && _pageCache.containsKey(key)) {
      emit(
        state.copyWith(
          status: ClientsStatus.loaded,
          clients: _pageCache[key],
          nextPageNumber: _nextPageCache[key],
          clearNextPage: _nextPageCache[key] == null,
          totalCount: _totalCache[key] ?? 0,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ClientsStatus.loading, clearError: true));

    try {
      final PaginatedClients result = await _repository.fetchClients(
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
          status: ClientsStatus.loaded,
          clients: result.results,
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
      AppLogger.session('failed to load clients: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final int nextPage = state.nextPageNumber!;
    final String key = _cacheKey;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedClients result = await _repository.fetchClients(
        page: nextPage,
        pageSize: PAGE_SIZE,
        query: _effectiveQuery,
        rangeParamsByKey: _rangeParams,
      );

      final List<Client> merged = [...state.clients, ...result.results];
      _pageCache[key] = merged;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          clients: merged,
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
      AppLogger.session('failed to load more clients: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> selectStatusView(ClientStatus? view) async {
    emit(state.copyWith(statusView: view, clearStatusView: view == null));
    await load();
  }

  Future<void> applyQuery(ClientsQuery query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(query: const ClientsQuery()));
    await load();
  }

  void updateSearchQuery(String value) =>
      emit(state.copyWith(searchQuery: value));

  Future<void> submitSearch(String value) async {
    final String term = value.trim();
    final bool byName = state.searchScope == ClientSearchScope.companyName;

    AppLogger.session(
      'client search submitted (${byName ? 'company_name' : 'address'})',
    );

    emit(
      state.copyWith(
        searchQuery: value,
        query: state.query.copyWith(
          companyName: byName ? term : '',
          address: byName ? '' : term,
        ),
      ),
    );
    await load();
  }

  Future<void> setSearchScope(ClientSearchScope scope) async {
    if (scope == state.searchScope) return;
    emit(state.copyWith(searchScope: scope));
    if (state.searchQuery.trim().isNotEmpty) {
      await submitSearch(state.searchQuery);
    }
  }

  Future<void> clearSearch() async {
    if (!state.query.hasSearch && state.searchQuery.isEmpty) return;
    emit(
      state.copyWith(
        searchQuery: '',
        query: state.query.copyWith(companyName: '', address: ''),
      ),
    );
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
        status: ClientsStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
