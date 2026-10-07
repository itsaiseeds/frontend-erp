import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../data/models/lab_testing.dart';

enum LabTestingsStatus { initial, loading, loaded, failure }

class LabTestingsState extends Equatable {
  final LabTestingsStatus status;
  final List<LabTesting> tests;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final ClientsQuery query;
  final String searchQuery;
  final bool hasNoSearchMatch;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;

  const LabTestingsState({
    this.status = LabTestingsStatus.initial,
    this.tests = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const ClientsQuery(),
    this.searchQuery = '',
    this.hasNoSearchMatch = false,
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => nextPageNumber != null;

  LabTestingsState copyWith({
    LabTestingsStatus? status,
    List<LabTesting>? tests,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    ClientsQuery? query,
    String? searchQuery,
    bool? hasNoSearchMatch,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LabTestingsState(
      status: status ?? this.status,
      tests: tests ?? this.tests,
      availableFilters: availableFilters ?? this.availableFilters,
      availableSorts: availableSorts ?? this.availableSorts,
      query: query ?? this.query,
      searchQuery: searchQuery ?? this.searchQuery,
      hasNoSearchMatch: hasNoSearchMatch ?? this.hasNoSearchMatch,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      nextPageNumber: clearNextPage
          ? null
          : (nextPageNumber ?? this.nextPageNumber),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    tests,
    availableFilters,
    availableSorts,
    query,
    searchQuery,
    hasNoSearchMatch,
    page,
    totalCount,
    nextPageNumber,
    isLoadingMore,
    errorMessage,
  ];
}
