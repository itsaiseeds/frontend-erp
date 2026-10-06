import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../data/models/return_order.dart';
import '../../data/models/return_orders_query.dart';

enum ReturnOrdersStatus { initial, loading, loaded, failure }

class ReturnOrdersState extends Equatable {
  final ReturnOrdersStatus status;
  final List<ReturnOrder> returnOrders;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final ReturnOrdersQuery query;

  /// Raw text in the search box. ``get-return-orders`` takes no free-text
  /// param, so it narrows the rows already loaded rather than the request.
  final String searchQuery;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;

  const ReturnOrdersState({
    this.status = ReturnOrdersStatus.initial,
    this.returnOrders = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const ReturnOrdersQuery(),
    this.searchQuery = '',
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  ReturnOrdersState copyWith({
    ReturnOrdersStatus? status,
    List<ReturnOrder>? returnOrders,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    ReturnOrdersQuery? query,
    String? searchQuery,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReturnOrdersState(
      status: status ?? this.status,
      returnOrders: returnOrders ?? this.returnOrders,
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

  bool get isLoading => status == ReturnOrdersStatus.loading;

  bool get hasSearch => searchQuery.trim().isNotEmpty;

  bool get hasMore => nextPageNumber != null;

  bool get isEmpty => status == ReturnOrdersStatus.loaded && returnOrders.isEmpty;

  /// The rows the list should render: the loaded returns, narrowed by whatever
  /// is in the search box.
  List<ReturnOrder> get visibleReturnOrders {
    if (!hasSearch) return returnOrders;
    return returnOrders
        .where((item) => item.matches(searchQuery))
        .toList(growable: false);
  }

  /// True when a term was typed and nothing on screen matches it, so the list
  /// can say so rather than showing rows the user did not ask for.
  bool get hasNoSearchMatch => hasSearch && visibleReturnOrders.isEmpty;

  @override
  List<Object?> get props => [
    status,
    returnOrders,
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
