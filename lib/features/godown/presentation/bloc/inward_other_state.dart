import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../data/models/inward_other_material.dart';

enum InwardOtherStatusState { initial, loading, loaded, failure }

class InwardOtherState extends Equatable {
  final InwardOtherStatusState status;
  final List<InwardOtherMaterial> lots;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final ClientsQuery query;
  final String searchQuery;
  final bool hasNoSearchMatch;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final bool isMutating;
  final String? errorMessage;

  const InwardOtherState({
    this.status = InwardOtherStatusState.initial,
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
    this.isMutating = false,
    this.errorMessage,
  });

  bool get hasMore => nextPageNumber != null;

  InwardOtherState copyWith({
    InwardOtherStatusState? status,
    List<InwardOtherMaterial>? lots,
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
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InwardOtherState(
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
      isMutating: isMutating ?? this.isMutating,
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
    isMutating,
    errorMessage,
  ];
}
