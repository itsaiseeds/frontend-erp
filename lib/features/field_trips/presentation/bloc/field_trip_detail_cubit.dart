import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/field_trips_repository.dart';
import '../../data/models/field_trip.dart';
import '../../data/models/paginated_field_trips.dart';
import 'field_trip_detail_state.dart';

class FieldTripDetailCubit extends SafeCubit<FieldTripDetailState> {
  final FieldTripsRepository _repository;

  FieldTripDetailCubit({
    required FieldTripsRepository repository,
    required FieldTrip trip,
  }) : _repository = repository,
       super(FieldTripDetailState(trip: trip));

  /// The row that was tapped already carries the whole plan, so the screen
  /// paints from it immediately and only refetches to catch an approval that
  /// landed while the list was open.
  Future<void> load() async {
    emit(
      state.copyWith(status: FieldTripDetailStatus.loaded, clearError: true),
    );
    await Future.wait([_refreshTrip(), loadFarmers()]);
  }

  Future<void> refresh() => load();

  Future<void> _refreshTrip() async {
    try {
      final FieldTrip? fresh = await _repository.fetchFieldTripByPublicId(
        state.trip.publicId,
      );
      if (fresh != null) emit(state.copyWith(trip: fresh));
    } on ApiException {
      // The tapped row is still a usable plan, so a failed refresh is left
      // to the farmers section to report rather than blanking the screen.
    } catch (e) {
      AppLogger.session('failed to refresh field trip: $e');
    }
  }

  Future<void> loadFarmers() async {
    emit(state.copyWith(isLoadingFarmers: true, clearFarmersError: true));

    try {
      final PaginatedFarmerVisits result = await _repository.fetchFarmerVisits(
        state.trip.publicId,
      );
      emit(
        state.copyWith(
          farmers: result.results,
          farmerFilters: result.availableFilters,
          farmerSorts: result.availableSorts,
          isLoadingFarmers: false,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          isLoadingFarmers: false,
          farmersErrorMessage: e.message,
        ),
      );
    } catch (e) {
      AppLogger.session('failed to load farmer visits: $e');
      emit(
        state.copyWith(
          isLoadingFarmers: false,
          farmersErrorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }
  }

  /// A salesperson may have only one trip out at a time, so the app checks
  /// for one before offering to start this one -- the constraint is a 400
  /// otherwise, which says nothing useful in the field.
  Future<FieldTrip?> findBlockingRunningTrip() async {
    try {
      final FieldTrip? running = await _repository.fetchRunningTrip();
      if (running == null) return null;
      return running.publicId == state.trip.publicId ? null : running;
    } on ApiException {
      // The server enforces the constraint regardless; a failed lookup must
      // not stop a legitimate start.
      return null;
    }
  }

  Future<void> start() => _act(
    () => _repository.startFieldTrip(state.trip.publicId),
    FieldTripAction.started,
  );

  Future<void> end() => _act(
    () => _repository.endFieldTrip(state.trip.publicId),
    FieldTripAction.ended,
  );

  Future<void> delete() => _act(
    () => _repository.deleteFieldTrip(state.trip.publicId),
    FieldTripAction.deleted,
  );

  Future<void> _act(
    Future<void> Function() call,
    FieldTripAction action,
  ) async {
    if (state.isActing) return;
    emit(state.copyWith(isActing: true, clearError: true));

    try {
      await call();
      emit(
        state.copyWith(
          isActing: false,
          completedAction: action,
          didChange: true,
        ),
      );
      // A deleted trip has nothing left to show, so only the survivors
      // refetch themselves.
      if (action != FieldTripAction.deleted) await load();
    } on ApiException catch (e) {
      emit(state.copyWith(isActing: false, errorMessage: e.message));
    } catch (e) {
      AppLogger.session('field trip action failed: $e');
      emit(
        state.copyWith(
          isActing: false,
          errorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }
  }

  void acknowledgeAction() =>
      emit(state.copyWith(completedAction: FieldTripAction.none));

  void acknowledgeError() => emit(state.copyWith(clearError: true));

  void markChanged() => emit(state.copyWith(didChange: true));
}
