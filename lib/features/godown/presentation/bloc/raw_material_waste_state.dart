import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../data/models/raw_material_waste.dart';

enum RawMaterialWasteStatusState { initial, loading, loaded, failure }

class RawMaterialWasteState extends Equatable {
  final RawMaterialWasteStatusState status;
  final List<RawMaterialWaste> wastes;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final ClientsQuery query;
  final String searchQuery;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final bool isMutating;
  final String? errorMessage;

  const RawMaterialWasteState({
    this.status = RawMaterialWasteStatusState.initial,
    this.wastes = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const ClientsQuery(),
    this.searchQuery = '',
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.errorMessage,
  });

  bool get hasMore => nextPageNumber != null;

  RawMaterialWasteState copyWith({
    RawMaterialWasteStatusState? status,
    List<RawMaterialWaste>? wastes,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    ClientsQuery? query,
    String? searchQuery,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RawMaterialWasteState(
      status: status ?? this.status,
      wastes: wastes ?? this.wastes,
      availableFilters: availableFilters ?? this.availableFilters,
      availableSorts: availableSorts ?? this.availableSorts,
      query: query ?? this.query,
      searchQuery: searchQuery ?? this.searchQuery,
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
    wastes,
    availableFilters,
    availableSorts,
    query,
    searchQuery,
    page,
    totalCount,
    nextPageNumber,
    isLoadingMore,
    isMutating,
    errorMessage,
  ];
}
