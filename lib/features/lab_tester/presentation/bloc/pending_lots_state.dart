import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../../godown/data/models/inward_raw_material.dart';

enum PendingLotsStatus { initial, loading, loaded, failure }

class PendingLotsState extends Equatable {
  final PendingLotsStatus status;
  final List<InwardRawMaterial> lots;
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

  const PendingLotsState({
    this.status = PendingLotsStatus.initial,
    this.lots = const [],
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

  PendingLotsState copyWith({
    PendingLotsStatus? status,
    List<InwardRawMaterial>? lots,
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
    return PendingLotsState(
      status: status ?? this.status,
      lots: lots ?? this.lots,
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
    lots,
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
