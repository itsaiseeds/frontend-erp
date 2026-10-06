import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import '../../../clients/data/models/client_filter.dart';
import 'return_order.dart';

class PaginatedReturnOrders extends Equatable {
  final int totalCount;
  final int totalPages;
  final int? nextPageNumber;
  final int? previousPageNumber;
  final List<ReturnOrder> results;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;

  const PaginatedReturnOrders({
    this.totalCount = 0,
    this.totalPages = 0,
    this.nextPageNumber,
    this.previousPageNumber,
    this.results = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
  });

  factory PaginatedReturnOrders.fromJson(Map<String, dynamic> json) {
    return PaginatedReturnOrders(
      totalCount: JsonParser.asInt(json['total_count']),
      totalPages: JsonParser.asInt(json['total_pages']),
      nextPageNumber: JsonParser.asNullableInt(json['next_page_number']),
      previousPageNumber: JsonParser.asNullableInt(
        json['previous_page_number'],
      ),
      results: JsonParser.asList(json['results'], ReturnOrder.fromJson),
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
