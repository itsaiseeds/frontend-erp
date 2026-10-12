import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../data/godown_repository.dart';
import '../../data/models/godown_page.dart';
import '../../data/models/raw_material_waste.dart';
import 'raw_material_waste_state.dart';

class RawMaterialWasteCubit extends SafeCubit<RawMaterialWasteState> {
  final GodownRepository _repository;

  RawMaterialWasteCubit({required GodownRepository repository})
    : _repository = repository,
      super(const RawMaterialWasteState());

  static const int _pageSize = 20;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: RawMaterialWasteStatusState.loading,
        clearError: true,
      ),
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

  Future<void> _fetch({required int page, required bool replace}) async {
    try {
      final Map<String, dynamic> params = state.query.toQueryParameters(
        page: page,
        pageSize: _pageSize,
        rangeParamsByKey: const {},
      );

      final GodownPage<RawMaterialWaste> result = await _repository
          .fetchRawMaterialWastes(queryParams: params);

      final List<RawMaterialWaste> merged = replace
          ? result.results
          : [...state.wastes, ...result.results];

      emit(
        state.copyWith(
          status: RawMaterialWasteStatusState.loaded,
          wastes: merged,
          availableFilters: result.availableFilters.isEmpty
              ? state.availableFilters
              : result.availableFilters,
          availableSorts: result.availableSorts.isEmpty
              ? state.availableSorts
              : result.availableSorts,
          page: page,
          totalCount: result.totalCount,
          nextPageNumber: result.nextPageNumber,
          clearNextPage: result.nextPageNumber == null,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: replace ? RawMaterialWasteStatusState.failure : state.status,
          isLoadingMore: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  void updateSearchQuery(String value) =>
      emit(state.copyWith(searchQuery: value));

  Future<void> applyQuery(ClientsQuery query) async {
    emit(state.copyWith(query: query));
    await load();
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(query: const ClientsQuery()));
    await load();
  }

  Future<bool> recordWaste({
    required String productPublicId,
    required String quantityKg,
    String? reason,
  }) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      await _repository.createRawMaterialWaste(
        productPublicId: productPublicId,
        quantityKg: quantityKg,
        reason: reason,
      );
      emit(state.copyWith(isMutating: false));
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: error.message));
      return false;
    }
  }

  Future<bool> updateWaste({
    required String publicId,
    String? quantityKg,
    String? reason,
  }) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      await _repository.updateRawMaterialWaste(
        publicId: publicId,
        quantityKg: quantityKg,
        reason: reason,
      );
      emit(state.copyWith(isMutating: false));
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: error.message));
      return false;
    }
  }

  Future<bool> deleteWaste(String publicId) async {
    emit(state.copyWith(isMutating: true, clearError: true));
    try {
      await _repository.deleteRawMaterialWaste(publicId);
      emit(state.copyWith(isMutating: false));
      await refresh();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isMutating: false, errorMessage: error.message));
      return false;
    }
  }
}
