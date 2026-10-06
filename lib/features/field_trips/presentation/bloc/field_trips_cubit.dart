import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/field_trips_repository.dart';
import '../../data/models/field_trip.dart';
import '../../data/models/field_trip_status.dart';
import '../../data/models/paginated_field_trips.dart';
import 'field_trips_state.dart';

class FieldTripsCubit extends SafeCubit<FieldTripsState> {
  final FieldTripsRepository _repository;

  final Map<String, List<FieldTrip>> _pageCache = {};
  final Map<String, int?> _nextPageCache = {};
  final Map<String, int> _totalCache = {};

  FieldTripsCubit({required FieldTripsRepository repository})
    : _repository = repository,
      super(const FieldTripsState());

  static const int PAGE_SIZE = 10;

  Future<void> load({bool forceRefresh = false}) async {
    final String key = state.query.cacheKey;

    if (!forceRefresh && _pageCache.containsKey(key)) {
      emit(
        state.copyWith(
          status: FieldTripsStatus.loaded,
          trips: _pageCache[key],
          nextPageNumber: _nextPageCache[key],
          clearNextPage: _nextPageCache[key] == null,
          totalCount: _totalCache[key] ?? 0,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(status: FieldTripsStatus.loading, clearError: true));

    try {
      final PaginatedFieldTrips result = await _repository.fetchFieldTrips(
        page: 1,
        pageSize: PAGE_SIZE,
        query: state.query,
      );

      _cache(key, result.results, result.nextPageNumber, result.totalCount);

      emit(
        state.copyWith(
          status: FieldTripsStatus.loaded,
          trips: result.results,
          page: 1,
          totalCount: result.totalCount,
          nextPageNumber: result.nextPageNumber,
          clearNextPage: result.nextPageNumber == null,
        ),
      );
    } on ApiException catch (e) {
      _emitFailure(e.message);
    } catch (e) {
      AppLogger.session('failed to load field trips: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final int nextPage = state.nextPageNumber!;
    final String key = state.query.cacheKey;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedFieldTrips result = await _repository.fetchFieldTrips(
        page: nextPage,
        pageSize: PAGE_SIZE,
        query: state.query,
      );

      final List<FieldTrip> merged = [...state.trips, ...result.results];
      _cache(key, merged, result.nextPageNumber, result.totalCount);

      emit(
        state.copyWith(
          trips: merged,
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
      AppLogger.session('failed to load more field trips: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> selectStatus(FieldTripStatus? status) async {
    if (state.query.status == status) return;
    emit(
      state.copyWith(
        query: state.query.copyWith(
          status: status,
          clearStatus: status == null,
        ),
      ),
    );
    await load();
  }

  /// Narrows the list to a village. The backend matches a substring, so
  /// the raw text goes straight through.
  Future<void> searchVillage(String village) async {
    if (state.query.village.trim() == village.trim()) return;
    emit(state.copyWith(query: state.query.copyWith(village: village)));
    await load();
  }

  Future<void> refresh() {
    _pageCache.clear();
    _nextPageCache.clear();
    _totalCache.clear();
    return load(forceRefresh: true);
  }

  void _cache(String key, List<FieldTrip> trips, int? nextPage, int total) {
    _pageCache[key] = trips;
    _nextPageCache[key] = nextPage;
    _totalCache[key] = total;
  }

  void _emitFailure(String message) {
    final String trimmed = message.trim();
    emit(
      state.copyWith(
        status: FieldTripsStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
