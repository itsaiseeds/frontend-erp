import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client_filter.dart';
import '../../data/models/cart_line.dart';
import '../../data/models/product_packaging.dart';
import '../../data/models/products_query.dart';

enum ProductsStatus { initial, loading, loaded, failure }

class ProductsState extends Equatable {
  final ProductsStatus status;
  final List<ProductPackaging> products;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;
  final ProductsQuery query;
  final String searchQuery;
  final int page;
  final int totalCount;
  final int? nextPageNumber;
  final bool isLoadingMore;
  final String? errorMessage;
  final Map<String, CartLine> cart;

  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.query = const ProductsQuery(),
    this.searchQuery = '',
    this.page = 1,
    this.totalCount = 0,
    this.nextPageNumber,
    this.isLoadingMore = false,
    this.errorMessage,
    this.cart = const {},
  });

  ProductsState copyWith({
    ProductsStatus? status,
    List<ProductPackaging>? products,
    List<ClientFilter>? availableFilters,
    List<ClientSort>? availableSorts,
    ProductsQuery? query,
    String? searchQuery,
    int? page,
    int? totalCount,
    int? nextPageNumber,
    bool clearNextPage = false,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    Map<String, CartLine>? cart,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
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
      cart: cart ?? this.cart,
    );
  }

  bool get isLoading => status == ProductsStatus.loading;

  bool get hasMore => nextPageNumber != null;

  bool get isEmpty => status == ProductsStatus.loaded && products.isEmpty;

  List<CartLine> get cartLines => cart.values.toList();

  int get cartItemCount =>
      cart.values.fold(0, (total, line) => total + line.quantity);

  num get cartTotal =>
      cart.values.fold<num>(0, (total, line) => total + line.lineTotal);

  bool get hasCart => cart.isNotEmpty;

  int quantityOf(String packagingPublicId) =>
      cart[packagingPublicId]?.quantity ?? 0;

  @override
  List<Object?> get props => [
    status,
    products,
    availableFilters,
    availableSorts,
    query,
    searchQuery,
    page,
    totalCount,
    nextPageNumber,
    isLoadingMore,
    errorMessage,
    cart,
  ];
}
