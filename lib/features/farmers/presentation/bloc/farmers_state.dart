import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../../field_trips/data/models/farmer_visit.dart';
import '../../data/models/farmers_query.dart';

enum FarmersStatus { initial, loading, loaded, failure }

class FarmersState extends Equatable {
  final FarmersStatus status;
  final List<FarmerVisit> farmers;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final FarmersQuery query;
  final String searchQuery;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;

  const FarmersState({
    this.status = FarmersStatus.initial,
    this.farmers = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const FarmersQuery(),
    this.searchQuery = '',
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  FarmersState copyWith({
    FarmersStatus? status,
    List<FarmerVisit>? farmers,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    FarmersQuery? query,
    String? searchQuery,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FarmersState(
      status: status ?? this.status,
      farmers: farmers ?? this.farmers,
      availableFilters: availableFilters ?? this.availableFilters,
      availableSorts: availableSorts ?? this.availableSorts,
      query: query ?? this.query,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      nextPageNumber: clearNextPage
          ? null
          : nextPageNumber ?? this.nextPageNumber,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == FarmersStatus.loading;

  bool get hasMore => nextPageNumber != null;

  bool get isEmpty => status == FarmersStatus.loaded && farmers.isEmpty;

  @override
  List<Object?> get props => [
    status,
    farmers,
    availableFilters,
    availableSorts,
    query,
    searchQuery,
    page,
    totalCount,
    nextPageNumber,
    isLoadingMore,
    errorMessage,
  ];
}
