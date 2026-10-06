import 'package:equatable/equatable.dart';

import 'field_trip_status.dart';

/// What the list screen is asking the backend for. A null ``status`` is the
/// "All" chip -- the param is dropped rather than sent empty.
class FieldTripsQuery extends Equatable {
  final FieldTripStatus? status;
  final String village;
  final String? sort;

  const FieldTripsQuery({this.status, this.village = '', this.sort});

  FieldTripsQuery copyWith({
    FieldTripStatus? status,
    bool clearStatus = false,
    String? village,
    String? sort,
    bool clearSort = false,
  }) {
    return FieldTripsQuery(
      status: clearStatus ? null : status ?? this.status,
      village: village ?? this.village,
      sort: clearSort ? null : sort ?? this.sort,
    );
  }

  bool get hasFilters => status != null || village.trim().isNotEmpty;

  /// The list is ordered newest first by the server: a trip that has not
  /// run is ordered by when it is due to start, and because a trip is
  /// started and ended on the day it was planned for, that same ordering
  /// puts the most recently finished work on top once it has run.
  ///
  /// Asking for ``-ended_at`` instead would be rejected: the endpoint
  /// whitelists only ``expected_start_at`` and ``created_at``.
  static const String SORT_EXPECTED_START = '-expected_start_at';

  String get effectiveSort => sort ?? SORT_EXPECTED_START;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int pageSize,
  }) {
    final String? rawStatus = status == null
        ? null
        : FieldTripStatusX.rawOf(status!);
    final String trimmedVillage = village.trim();

    return {
      'page': page,
      'page_size': pageSize,
      'status': ?rawStatus,
      if (trimmedVillage.isNotEmpty) 'village': trimmedVillage,
      'sort': effectiveSort,
    };
  }

  /// The cache key for one page set: two queries asking the same thing share
  /// their loaded pages.
  String get cacheKey =>
      '${status?.name ?? ''}#${village.trim().toLowerCase()}#$effectiveSort';

  @override
  List<Object?> get props => [status, village, sort];
}
