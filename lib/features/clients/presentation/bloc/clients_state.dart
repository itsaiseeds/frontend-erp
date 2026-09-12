import 'package:equatable/equatable.dart';

import '../../data/models/client.dart';
import '../../data/models/client_filter.dart';
import '../../data/models/client_status.dart';
import '../../data/models/clients_query.dart';

enum ClientsStatus { initial, loading, loaded, failure }

enum ClientSearchScope { companyName, address }

class ClientsState extends Equatable {
  final ClientsStatus status;
  final List<Client> clients;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final ClientsQuery query;
  final ClientStatus? statusView;
  final String searchQuery;
  final ClientSearchScope searchScope;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;

  const ClientsState({
    this.status = ClientsStatus.initial,
    this.clients = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const ClientsQuery(),
    this.statusView,
    this.searchQuery = '',
    this.searchScope = ClientSearchScope.companyName,
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  ClientsState copyWith({
    ClientsStatus? status,
    List<Client>? clients,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    ClientsQuery? query,
    ClientStatus? statusView,
    bool clearStatusView = false,
    String? searchQuery,
    ClientSearchScope? searchScope,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClientsState(
      status: status ?? this.status,
      clients: clients ?? this.clients,
      availableFilters: availableFilters ?? this.availableFilters,
      availableSorts: availableSorts ?? this.availableSorts,
      query: query ?? this.query,
      statusView: clearStatusView ? null : statusView ?? this.statusView,
      searchQuery: searchQuery ?? this.searchQuery,
      searchScope: searchScope ?? this.searchScope,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      nextPageNumber: clearNextPage
          ? null
          : nextPageNumber ?? this.nextPageNumber,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  List<Client> get visibleClients => clients;

  bool get isLoading => status == ClientsStatus.loading;

  bool get hasMore => nextPageNumber != null;

  bool get isEmpty => status == ClientsStatus.loaded && visibleClients.isEmpty;

  @override
  List<Object?> get props => [
    status,
    clients,
    availableFilters,
    availableSorts,
    query,
    statusView,
    searchQuery,
    searchScope,
    page,
    totalCount,
    nextPageNumber,
    isLoadingMore,
    errorMessage,
  ];
}
