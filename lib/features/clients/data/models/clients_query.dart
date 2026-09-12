import 'package:equatable/equatable.dart';

class DateRange extends Equatable {
  final DateTime? from;
  final DateTime? to;

  const DateRange({this.from, this.to});

  bool get isEmpty => from == null && to == null;

  @override
  List<Object?> get props => [from, to];
}

class ClientsQuery extends Equatable {
  static const String COMPANY_NAME_PARAM = 'company_name';
  static const String ADDRESS_PARAM = 'address';

  final Map<String, Set<String>> selections;
  final Map<String, DateRange> ranges;
  final String companyName;
  final String address;
  final String? sort;
  final bool descending;

  const ClientsQuery({
    this.selections = const {},
    this.ranges = const {},
    this.companyName = '',
    this.address = '',
    this.sort,
    this.descending = true,
  });

  ClientsQuery copyWith({
    Map<String, Set<String>>? selections,
    Map<String, DateRange>? ranges,
    String? companyName,
    String? address,
    String? sort,
    bool clearSort = false,
    bool? descending,
  }) {
    return ClientsQuery(
      selections: selections ?? this.selections,
      ranges: ranges ?? this.ranges,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      sort: clearSort ? null : sort ?? this.sort,
      descending: descending ?? this.descending,
    );
  }

  ClientsQuery withSelection(String key, Set<String> values) {
    final Map<String, Set<String>> next = Map.of(selections);
    if (values.isEmpty) {
      next.remove(key);
    } else {
      next[key] = values;
    }
    return copyWith(selections: next);
  }

  ClientsQuery withRange(String key, DateRange range) {
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

  bool get hasSearch =>
      companyName.trim().isNotEmpty || address.trim().isNotEmpty;

  bool get hasFilters => activeCount > 0;

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int pageSize,
    required Map<String, List<String>> rangeParamsByKey,
  }) {
    final Map<String, dynamic> params = {'page': page, 'page_size': pageSize};

    if (companyName.trim().isNotEmpty) {
      params[COMPANY_NAME_PARAM] = companyName.trim();
    }
    if (address.trim().isNotEmpty) {
      params[ADDRESS_PARAM] = address.trim();
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
  List<Object?> get props => [
    selections,
    ranges,
    companyName,
    address,
    sort,
    descending,
  ];
}
