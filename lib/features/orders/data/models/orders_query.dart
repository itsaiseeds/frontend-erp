import 'package:equatable/equatable.dart';

import '../../../clients/data/models/clients_query.dart';

/// The order list has no free-text search param -- ``client`` and ``product``
/// are select filters -- so search is not part of the query.
class OrdersQuery extends Equatable {
  final Map<String, Set<String>> selections;
  final Map<String, DateRange> ranges;
  final String? sort;
  final bool descending;

  const OrdersQuery({
    this.selections = const {},
    this.ranges = const {},
    this.sort,
    this.descending = false,
  });

  OrdersQuery copyWith({
    Map<String, Set<String>>? selections,
    Map<String, DateRange>? ranges,
    String? sort,
    bool clearSort = false,
    bool? descending,
  }) {
    return OrdersQuery(
      selections: selections ?? this.selections,
      ranges: ranges ?? this.ranges,
      sort: clearSort ? null : sort ?? this.sort,
      descending: descending ?? this.descending,
    );
  }

  int get activeCount => selections.length + ranges.length;

  bool get hasFilters => activeCount > 0;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int pageSize,
    required Map<String, List<String>> rangeParamsByKey,
  }) {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};

    selections.forEach((key, values) {
      if (values.isNotEmpty) params[key] = values.join(',');
    });

    ranges.forEach((key, range) {
      final List<String> names =
          rangeParamsByKey[key] ?? ['${key}_gte', '${key}_lte'];
      if (range.from != null && names.isNotEmpty) {
        params[names.first] = range.from!.toUtc().toIso8601String();
      }
      if (range.to != null && names.length > 1) {
        params[names[1]] = range.to!.toUtc().toIso8601String();
      }
    });

    final String? sortKey = sort;
    if (sortKey != null && sortKey.isNotEmpty) {
      params['sort'] = descending ? '-$sortKey' : sortKey;
    }

    return params;
  }

  /// The filter sheet is built around ClientsQuery; selections, ranges and
  /// sort are identical, so the two adapt rather than duplicating the sheet.
  ClientsQuery asClientsQuery() {
    return ClientsQuery(
      selections: selections,
      ranges: ranges,
      sort: sort,
      descending: descending,
    );
  }

  @override
  List<Object?> get props => [selections, ranges, sort, descending];
}

extension ClientsQueryAsOrdersQuery on ClientsQuery {
  OrdersQuery asOrdersQuery() {
    return OrdersQuery(
      selections: selections,
      ranges: ranges,
      sort: sort,
      descending: descending,
    );
  }
}
