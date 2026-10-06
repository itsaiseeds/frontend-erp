import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import '../../../clients/data/models/client_filter.dart';
import 'farmer_visit.dart';
import 'field_trip.dart';

class PaginatedFieldTrips extends Equatable {
  final int totalCount;
  final int totalPages;
  final int? nextPageNumber;
  final int? previousPageNumber;
  final List<FieldTrip> results;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;

  const PaginatedFieldTrips({
    this.totalCount = 0,
    this.totalPages = 0,
    this.nextPageNumber,
    this.previousPageNumber,
    this.results = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
  });

  factory PaginatedFieldTrips.fromJson(Map<String, dynamic> json) {
    return PaginatedFieldTrips(
      totalCount: JsonParser.asInt(json['total_count']),
      totalPages: JsonParser.asInt(json['total_pages']),
      nextPageNumber: JsonParser.asNullableInt(json['next_page_number']),
      previousPageNumber: JsonParser.asNullableInt(
        json['previous_page_number'],
      ),
      results: JsonParser.asList(json['results'], FieldTrip.fromJson),
      availableFilters: JsonParser.asList(
        json['available_filters'],
        ClientFilter.fromJson,
      ),
      availableSorts: JsonParser.asList(
        json['available_sorts'],
        ClientSort.fromJson,
      ),
    );
  }

  @override
  List<Object?> get props => [
    totalCount,
    totalPages,
    nextPageNumber,
    previousPageNumber,
    results,
    availableFilters,
    availableSorts,
  ];
}

class PaginatedFarmerVisits extends Equatable {
  final int totalCount;
  final int? nextPageNumber;
  final List<FarmerVisit> results;

  /// The crop / product / uses-our-products filters the server offers, so
  /// the filter sheet is driven by the API rather than by whatever happens
  /// to be on this page.
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;

  const PaginatedFarmerVisits({
    this.totalCount = 0,
    this.nextPageNumber,
    this.results = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
  });

  factory PaginatedFarmerVisits.fromJson(Map<String, dynamic> json) {
    return PaginatedFarmerVisits(
      totalCount: JsonParser.asInt(json['total_count']),
      nextPageNumber: JsonParser.asNullableInt(json['next_page_number']),
      results: JsonParser.asList(json['results'], FarmerVisit.fromJson),
      availableFilters: JsonParser.asList(
        json['available_filters'],
        ClientFilter.fromJson,
      ),
      availableSorts: JsonParser.asList(
        json['available_sorts'],
        ClientSort.fromJson,
      ),
    );
  }

  @override
  List<Object?> get props => [
    totalCount,
    nextPageNumber,
    results,
    availableFilters,
    availableSorts,
  ];
}
