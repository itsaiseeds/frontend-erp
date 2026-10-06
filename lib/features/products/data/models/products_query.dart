import 'package:equatable/equatable.dart';

import '../../../clients/data/models/clients_query.dart';

class ProductsQuery extends Equatable {
  static const String NAME_PARAM = 'name';

  final Map<String, Set<String>> selections;
  final Map<String, DateRange> ranges;
  final String name;
  final String? sort;
  final bool descending;

  const ProductsQuery({
    this.selections = const {},
    this.ranges = const {},
    this.name = '',
    this.sort,
    this.descending = false,
  });

  ProductsQuery copyWith({
    Map<String, Set<String>>? selections,
    Map<String, DateRange>? ranges,
    String? name,
    String? sort,
    bool clearSort = false,
    bool? descending,
  }) {
    return ProductsQuery(
      selections: selections ?? this.selections,
      ranges: ranges ?? this.ranges,
      name: name ?? this.name,
      sort: clearSort ? null : sort ?? this.sort,
      descending: descending ?? this.descending,
    );
  }

  ProductsQuery withSelection(String key, Set<String> values) {
    final Map<String, Set<String>> next = Map.of(selections);
    if (values.isEmpty) {
      next.remove(key);
    } else {
      next[key] = values;
    }
    return copyWith(selections: next);
  }

  ProductsQuery withRange(String key, DateRange range) {
    final Map<String, DateRange> next = Map.of(ranges);
    if (range.isEmpty) {
      next.remove(key);
    } else {
      next[key] = range;
    }
    return copyWith(ranges: next);
  }

  Set<String> valuesFor(String key) => selections[key] ?? const {};

  DateRange rangeFor(String key) => ranges[key] ?? const DateRange();

  int get activeCount => selections.length + ranges.length;

  bool get hasSearch => name.trim().isNotEmpty;

  bool get hasFilters => activeCount > 0;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int pageSize,
    required Map<String, List<String>> rangeParamsByKey,
  }) {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};

    if (name.trim().isNotEmpty) params[NAME_PARAM] = name.trim();

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
  List<Object?> get props => [selections, ranges, name, sort, descending];
}

extension ClientsQueryAsProductsQuery on ClientsQuery {
  ProductsQuery asProductsQuery({String name = ''}) {
    return ProductsQuery(
      selections: selections,
      ranges: ranges,
      name: name,
      sort: sort,
      descending: descending,
    );
  }
}
