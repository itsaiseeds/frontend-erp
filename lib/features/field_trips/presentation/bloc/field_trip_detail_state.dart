import '../../../clients/data/models/client_filter.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/farmer_visit.dart';
import '../../data/models/field_trip.dart';

enum FieldTripDetailStatus { initial, loading, loaded, failure }

/// What finished, so the screen can toast the right thing once and the list
/// behind it knows to refresh.
enum FieldTripAction { none, started, ended, deleted }

class FieldTripDetailState extends Equatable {
  final FieldTripDetailStatus status;
  final FieldTrip trip;
  final List<FarmerVisit> farmers;

  /// The crop / product filters the server offers for these visits, handed
  /// to the all-farmers screen so its sheet is API-driven.
  final List<ClientFilter> farmerFilters;
  final List<ClientSort> farmerSorts;
  final bool isLoadingFarmers;
  final String? farmersErrorMessage;

  /// True while a start / end / delete call is in flight, so the action
  /// cannot be fired twice.
  final bool isActing;
  final FieldTripAction completedAction;

  /// Set when the trip was changed here, so the list behind refreshes on pop.
  final bool didChange;
  final String? errorMessage;

  const FieldTripDetailState({
    this.status = FieldTripDetailStatus.initial,
    required this.trip,
    this.farmers = const [],
    this.farmerFilters = const [],
    this.farmerSorts = const [],
    this.isLoadingFarmers = false,
    this.farmersErrorMessage,
    this.isActing = false,
    this.completedAction = FieldTripAction.none,
    this.didChange = false,
    this.errorMessage,
  });

  FieldTripDetailState copyWith({
    FieldTripDetailStatus? status,
    FieldTrip? trip,
    List<FarmerVisit>? farmers,
    List<ClientFilter>? farmerFilters,
    List<ClientSort>? farmerSorts,
    bool? isLoadingFarmers,
    String? farmersErrorMessage,
    bool clearFarmersError = false,
    bool? isActing,
    FieldTripAction? completedAction,
    bool? didChange,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FieldTripDetailState(
      status: status ?? this.status,
      trip: trip ?? this.trip,
      farmers: farmers ?? this.farmers,
      farmerFilters: farmerFilters ?? this.farmerFilters,
      farmerSorts: farmerSorts ?? this.farmerSorts,
      isLoadingFarmers: isLoadingFarmers ?? this.isLoadingFarmers,
      farmersErrorMessage: clearFarmersError
          ? null
          : farmersErrorMessage ?? this.farmersErrorMessage,
      isActing: isActing ?? this.isActing,
      completedAction: completedAction ?? this.completedAction,
      didChange: didChange ?? this.didChange,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == FieldTripDetailStatus.loading;

  @override
  List<Object?> get props => [
    status,
    trip,
    farmers,
    farmerFilters,
    farmerSorts,
    isLoadingFarmers,
    farmersErrorMessage,
    isActing,
    completedAction,
    didChange,
    errorMessage,
  ];
}
