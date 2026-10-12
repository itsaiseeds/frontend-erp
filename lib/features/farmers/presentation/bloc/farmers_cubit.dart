import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../clients/data/models/client_filter.dart';
import '../../../field_trips/data/models/farmer_visit.dart';
import '../../data/farmers_repository.dart';
import '../../data/models/farmers_query.dart';
import '../../data/models/paginated_farmers.dart';
import 'farmers_state.dart';

class FarmersCubit extends SafeCubit<FarmersState> {
  final FarmersRepository _repository;

  final Map<String, List<FarmerVisit>> _pageCache = {};
  final Map<String, int?> _nextPageCache = {};
  final Map<String, int> _totalCache = {};

  FarmersCubit({required FarmersRepository repository})
    : _repository = repository,
      super(const FarmersState());

  static const int PAGE_SIZE = 10;

  String get _cacheKey {
    final FarmersQuery query = state.query;
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
        '#search=${query.search}'
        '#sort=${query.sort}'
        '#desc=${query.descending}';
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
          status: FarmersStatus.loaded,
          farmers: _pageCache[key],
          nextPageNumber: _nextPageCache[key],
          clearNextPage: _nextPageCache[key] == null,
          totalCount: _totalCache[key] ?? 0,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: FarmersStatus.loading, clearError: true));

    try {
      final PaginatedFarmers result = await _repository.fetchFarmers(
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
          status: FarmersStatus.loaded,
          farmers: result.results,
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
      AppLogger.session('failed to load farmers: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final int nextPage = state.nextPageNumber!;
    final String key = _cacheKey;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedFarmers result = await _repository.fetchFarmers(
        page: nextPage,
        pageSize: PAGE_SIZE,
        query: state.query,
        rangeParamsByKey: _rangeParams,
      );

      final List<FarmerVisit> merged = [...state.farmers, ...result.results];
      _pageCache[key] = merged;
      _nextPageCache[key] = result.nextPageNumber;
      _totalCache[key] = result.totalCount;

      emit(
        state.copyWith(
          farmers: merged,
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
      AppLogger.session('failed to load more farmers: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> applyQuery(FarmersQuery query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(query: const FarmersQuery()));
    await load();
  }

  void updateSearchQuery(String value) =>
      emit(state.copyWith(searchQuery: value));

  Future<void> submitSearch(String value) async {
    final String term = value.trim();
    emit(
      state.copyWith(
        searchQuery: value,
        query: state.query.copyWith(search: term),
      ),
    );
    await load();
  }

  Future<void> clearSearch() async {
    if (!state.query.hasSearch && state.searchQuery.isEmpty) return;
    emit(
      state.copyWith(searchQuery: '', query: state.query.copyWith(search: '')),
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
        status: FarmersStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
