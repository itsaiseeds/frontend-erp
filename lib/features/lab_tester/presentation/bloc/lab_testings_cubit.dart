import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../../clients/data/models/client_filter.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../../godown/data/models/godown_page.dart';
import '../../data/lab_tester_repository.dart';
import '../../data/models/lab_testing.dart';
import 'lab_testings_state.dart';

/// The tested-reports tab: every lab test (all printable results), paginated
/// and filterable exactly like the godown lot lists, so the same sheet and
/// search bar drive it. Mirror of `PendingLotsCubit` -- only the row type
/// differs.
class LabTestingsCubit extends SafeCubit<LabTestingsState> {
  final LabTesterRepository _repository;

  LabTestingsCubit({required LabTesterRepository repository})
    : _repository = repository,
      super(const LabTestingsState());

  static const int _pageSize = 20;
  static const String PRODUCT_FILTER = 'product';

  Future<void> load() async {
    emit(state.copyWith(status: LabTestingsStatus.loading, clearError: true));
    await _fetch(page: 1, replace: true);
  }

  Future<void> refresh() => _fetch(page: 1, replace: true);

  Future<void> loadMore() async {
    final int? next = state.nextPageNumber;
    if (next == null || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _fetch(page: next, replace: false);
  }

  ClientsQuery get _effectiveQuery {
    final String term = state.searchQuery.trim();
    if (term.isEmpty) return state.query;

    final Set<String> products = _matchingValues(PRODUCT_FILTER, term);
    if (products.isEmpty) return state.query;
    return state.query.withSelection(PRODUCT_FILTER, products);
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

  bool get _hasNoSearchMatch {
    final String term = state.searchQuery.trim();
    if (term.isEmpty) return false;
    return _matchingValues(PRODUCT_FILTER, term).isEmpty;
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    if (replace && _hasNoSearchMatch) {
      emit(
        state.copyWith(
          status: LabTestingsStatus.loaded,
          tests: const [],
          page: 1,
          totalCount: 0,
          clearNextPage: true,
          hasNoSearchMatch: true,
          clearError: true,
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> params = _effectiveQuery.toQueryParameters(
        page: page,
        pageSize: _pageSize,
        rangeParamsByKey: const {},
      );

      final GodownPage<LabTesting> result = await _repository
          .fetchLabTestings(queryParams: params);

      final List<LabTesting> merged = replace
          ? result.results
          : [...state.tests, ...result.results];

      emit(
        state.copyWith(
          status: LabTestingsStatus.loaded,
          tests: merged,
          availableFilters: result.availableFilters,
          availableSorts: result.availableSorts,
          page: page,
          totalCount: result.totalCount,
          nextPageNumber: result.nextPageNumber,
          clearNextPage: result.nextPageNumber == null,
          isLoadingMore: false,
          hasNoSearchMatch: false,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: replace ? LabTestingsStatus.failure : state.status,
          isLoadingMore: false,
          errorMessage: error.message,
        ),
      );
    }
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
    emit(state.copyWith(searchQuery: value.trim()));
    emit(state.copyWith(hasNoSearchMatch: _hasNoSearchMatch));
    await load();
  }

  Future<void> clearSearch() async {
    emit(state.copyWith(searchQuery: '', hasNoSearchMatch: false));
    await load();
  }
}