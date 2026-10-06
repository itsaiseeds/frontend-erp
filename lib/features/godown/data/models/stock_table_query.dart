import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';

/// Which rows the stock table shows. Derived from the live position read: a
/// lot with no position has never been counted, so it reads as "not counted"
/// rather than "counted as zero".
enum StockCountFilter { all, counted, notCounted }

extension StockCountFilterLabel on StockCountFilter {
  String get label => switch (this) {
    StockCountFilter.all => AppStrings.STOCK_FILTER_ALL,
    StockCountFilter.counted => AppStrings.STOCK_FILTER_COUNTED,
    StockCountFilter.notCounted => AppStrings.STOCK_FILTER_NOT_COUNTED,
  };

  bool matches({required bool hasPosition}) => switch (this) {
    StockCountFilter.all => true,
    StockCountFilter.counted => hasPosition,
    StockCountFilter.notCounted => !hasPosition,
  };
}

enum StockSort { nameAsc, availableDesc, availableAsc }

extension StockSortLabel on StockSort {
  String get label => switch (this) {
    StockSort.nameAsc => AppStrings.STOCK_SORT_NAME_ASC,
    StockSort.availableDesc => AppStrings.STOCK_SORT_AVAILABLE_DESC,
    StockSort.availableAsc => AppStrings.STOCK_SORT_AVAILABLE_ASC,
  };

  bool get isDefault => this == StockSort.nameAsc;
}

/// The user's chosen view of the stock table. Immutable so the filter sheet can
/// edit a draft copy and the screen can compare the two before applying.
class StockTableQuery extends Equatable {
  final String search;
  final StockCountFilter filter;
  final StockSort sort;

  const StockTableQuery({
    this.search = '',
    this.filter = StockCountFilter.all,
    this.sort = StockSort.nameAsc,
  });

  StockTableQuery copyWith({
    String? search,
    StockCountFilter? filter,
    StockSort? sort,
  }) => StockTableQuery(
    search: search ?? this.search,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
  );

  /// How many controls differ from the untouched default. Drives the badge on
  /// the filter button so a narrowed view is visible at a glance.
  int get activeCount =>
      (filter == StockCountFilter.all ? 0 : 1) + (sort.isDefault ? 0 : 1);

  @override
  List<Object?> get props => [search, filter, sort];
}

/// Case-insensitive match across the fields the table shows. Blank text
/// matches everything, so clearing the search box always restores the full
/// list.
bool stockRowMatches({
  required String query,
  required String title,
  String subtitle = '',
}) {
  final String term = query.trim().toLowerCase();
  if (term.isEmpty) return true;
  return title.toLowerCase().contains(term) ||
      subtitle.toLowerCase().contains(term);
}

/// Orders two rows for [sort]. An uncounted row has no available figure, so it
/// always sinks to the bottom instead of being treated as the smallest number.
int compareStockRows(
  StockSort sort, {
  required String title,
  required int? available,
  required String otherTitle,
  required int? otherAvailable,
}) {
  switch (sort) {
    case StockSort.nameAsc:
      return title.toLowerCase().compareTo(otherTitle.toLowerCase());
    case StockSort.availableDesc:
      return _compareAvailable(available, otherAvailable, descending: true);
    case StockSort.availableAsc:
      return _compareAvailable(available, otherAvailable, descending: false);
  }
}

int _compareAvailable(int? a, int? b, {required bool descending}) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return descending ? b.compareTo(a) : a.compareTo(b);
}
