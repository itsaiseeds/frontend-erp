import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../data/models/order.dart';
import '../../data/models/orders_query.dart';

enum OrdersStatus { initial, loading, loaded, failure }

class OrdersState extends Equatable {
  final OrdersStatus status;
  final List<Order> orders;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final OrdersQuery query;

  /// Raw text in the search box. The backend has no free-text param, so this
  /// is resolved against the client / product filter options and sent as ids.
  final String searchQuery;
  final bool hasNoSearchMatch;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const OrdersQuery(),
    this.searchQuery = '',
    this.hasNoSearchMatch = false,
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  OrdersState copyWith({
    OrdersStatus? status,
    List<Order>? orders,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    OrdersQuery? query,
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
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      availableFilters: availableFilters ?? this.availableFilters,
      availableSorts: availableSorts ?? this.availableSorts,
      query: query ?? this.query,
      searchQuery: searchQuery ?? this.searchQuery,
      hasNoSearchMatch: hasNoSearchMatch ?? this.hasNoSearchMatch,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      nextPageNumber: clearNextPage
          ? null
          : nextPageNumber ?? this.nextPageNumber,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == OrdersStatus.loading;

  bool get hasSearch => searchQuery.trim().isNotEmpty;

  bool get hasMore => nextPageNumber != null;

  bool get isEmpty => status == OrdersStatus.loaded && orders.isEmpty;

  @override
  List<Object?> get props => [
    status,
    orders,
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
