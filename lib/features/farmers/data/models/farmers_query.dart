import 'package:equatable/equatable.dart';

import '../../../clients/data/models/clients_query.dart';

/// Mirrors [ClientsQuery]'s shape for a single free-text search field plus
/// server-driven select/date-range filters and sort.
class FarmersQuery extends Equatable {
  static const String SEARCH_PARAM = 'farmer_name';

  final Map<String, Set<String>> selections;
  final Map<String, DateRange> ranges;
  final String search;
  final String? sort;
  final bool descending;

  const FarmersQuery({
    this.selections = const {},
    this.ranges = const {},
    this.search = '',
    this.sort,
    this.descending = true,
  });

  FarmersQuery copyWith({
    Map<String, Set<String>>? selections,
    Map<String, DateRange>? ranges,
    String? search,
    String? sort,
    bool clearSort = false,
    bool? descending,
  }) {
    return FarmersQuery(
      selections: selections ?? this.selections,
      ranges: ranges ?? this.ranges,
      search: search ?? this.search,
      sort: clearSort ? null : sort ?? this.sort,
      descending: descending ?? this.descending,
    );
  }

  FarmersQuery withSelection(String key, Set<String> values) {
    final Map<String, Set<String>> next = Map.of(selections);
    if (values.isEmpty) {
      next.remove(key);
    } else {
      next[key] = values;
    }
    return copyWith(selections: next);
  }

  FarmersQuery withRange(String key, DateRange range) {
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

  bool get hasSearch => search.trim().isNotEmpty;

  bool get hasFilters => activeCount > 0;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int pageSize,
    required Map<String, List<String>> rangeParamsByKey,
  }) {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};

    if (search.trim().isNotEmpty) {
      params[SEARCH_PARAM] = search.trim();
    }

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

    if (sort != null && sort!.isNotEmpty) {
      params['sort'] = descending ? '-$sort' : sort;
    }

    return params;
  }

  @override
  List<Object?> get props => [selections, ranges, search, sort, descending];
}
