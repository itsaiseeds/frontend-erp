import 'package:equatable/equatable.dart';

import '../../data/models/field_trip.dart';
import '../../data/models/field_trips_query.dart';

enum FieldTripsStatus { initial, loading, loaded, failure }

class FieldTripsState extends Equatable {
  final FieldTripsStatus status;
  final List<FieldTrip> trips;
  final FieldTripsQuery query;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;

  const FieldTripsState({
    this.status = FieldTripsStatus.initial,
    this.trips = const [],
    this.query = const FieldTripsQuery(),
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  FieldTripsState copyWith({
    FieldTripsStatus? status,
    List<FieldTrip>? trips,
    FieldTripsQuery? query,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FieldTripsState(
      status: status ?? this.status,
      trips: trips ?? this.trips,
      query: query ?? this.query,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      nextPageNumber: clearNextPage
          ? null
          : nextPageNumber ?? this.nextPageNumber,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == FieldTripsStatus.loading;

  bool get hasMore => nextPageNumber != null;

  bool get isEmpty => status == FieldTripsStatus.loaded && trips.isEmpty;

  /// The trip already out, if there is one. Only one can exist per
  /// salesperson, so the list itself is enough to answer the question.
  FieldTrip? get runningTrip {
    for (final FieldTrip trip in trips) {
      if (trip.canEnd) return trip;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    status,
    trips,
    query,
    page,
    totalCount,
    nextPageNumber,
    isLoadingMore,
    errorMessage,
  ];
}
