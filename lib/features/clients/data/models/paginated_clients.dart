import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'client.dart';
import 'client_filter.dart';

class PaginatedClients extends Equatable {
  final int totalCount;
  final int totalPages;
  final int? nextPageNumber;
  final int? previousPageNumber;
  final List<Client> results;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;

  const PaginatedClients({
    this.totalCount = 0,
    this.totalPages = 0,
    this.nextPageNumber,
    this.previousPageNumber,
    this.results = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
  });

  factory PaginatedClients.fromJson(Map<String, dynamic> json) {
    return PaginatedClients(
      totalCount: JsonParser.asInt(json['total_count']),
      totalPages: JsonParser.asInt(json['total_pages']),
      nextPageNumber: JsonParser.asNullableInt(json['next_page_number']),
      previousPageNumber: JsonParser.asNullableInt(
        json['previous_page_number'],
      ),
      results: JsonParser.asList(json['results'], Client.fromJson),
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
