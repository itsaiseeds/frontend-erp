import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../../clients/data/models/client_filter.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../data/godown_repository.dart';
import '../../data/models/godown_page.dart';
import '../../data/models/inward_raw_material.dart';
import '../../data/models/inward_raw_status.dart';
import 'inward_raw_state.dart';

class InwardRawCubit extends SafeCubit<InwardRawState> {
  final GodownRepository _repository;

  InwardRawCubit({required GodownRepository repository})
    : _repository = repository,
      super(const InwardRawState());

  static const int _pageSize = 20;
  static const String PRODUCT_FILTER = 'product';

  Future<void> load() async {
    emit(
      state.copyWith(status: InwardRawStatusState.loading, clearError: true),
    );
    await _fetch(page: 1, replace: true);
  }

  Future<void> refresh() => _fetch(page: 1, replace: true);

  Future<void> loadMore() async {
    final int? next = state.nextPageNumber;
    if (next == null || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    await _fetch(page: next, replace: false);
  }

  /// The list has no free-text param -- `product` is a select filter -- so a
  /// typed term is matched against the product filter's own option labels
  /// and sent as a real id, the same trick `OrdersCubit` uses.
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
          status: InwardRawStatusState.loaded,
          lots: const [],
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

      final GodownPage<InwardRawMaterial> result = await _repository
          .fetchInwardRawMaterials(queryParams: params);

      final List<InwardRawMaterial> merged = replace
          ? result.results
          : [...state.lots, ...result.results];

      emit(
        state.copyWith(
          status: InwardRawStatusState.loaded,
          lots: merged,
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
          status: replace ? InwardRawStatusState.failure : state.status,
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

  Future<bool> bookLot({
    required String productPublicId,
    required int partyId,
    required String lotNo,
    required String quantityKg,
    String? farmerName,
    DateTime? labSamplingDate,
  }) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      await _repository.createInwardRawMaterial(
        productPublicId: productPublicId,
        partyId: partyId,
        lotNo: lotNo,
        quantityKg: quantityKg,
        farmerName: farmerName,
        labSamplingDate: labSamplingDate,
      );
      emit(state.copyWith(isMutating: false));
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: error.message));
      return false;
    }
  }

  Future<bool> changeStatus(String publicId, InwardRawStatus status) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      await _repository.updateInwardRawMaterialStatus(
        publicId: publicId,
        status: status,
      );
      emit(state.copyWith(isMutating: false));
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: error.message));
      return false;
    }
  }

  Future<bool> deleteLot(String publicId) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      await _repository.deleteInwardRawMaterial(publicId);
      emit(state.copyWith(isMutating: false));
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: error.message));
      return false;
    }
  }
}
