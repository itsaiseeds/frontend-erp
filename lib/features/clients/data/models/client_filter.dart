import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

enum FilterKind { select, datetimeRange, unsupported }

class FilterOption extends Equatable {
  final String value;
  final String label;

  const FilterOption({required this.value, required this.label});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    final dynamic raw = json['value'];
    return FilterOption(
      value: raw == null ? '' : '$raw',
      label: JsonParser.asString(json['label']),
    );
  }

  @override
  List<Object?> get props => [value, label];
}

class ClientFilter extends Equatable {
  final String key;

  /// Display name supplied by the backend. Falls back to a humanised key so a
  /// filter added server-side still renders before a label is set for it.
  final String label;
  final FilterKind kind;
  final String description;
  final List<FilterOption> options;
  final List<String> params;

  const ClientFilter({
    required this.key,
    required this.kind,
    this.label = '',
    this.description = '',
    this.options = const [],
    this.params = const [],
  });

  factory ClientFilter.fromJson(Map<String, dynamic> json) {
    return ClientFilter(
      key: JsonParser.asString(json['filter']),
      label: JsonParser.asString(json['label']),
      kind: _kindFrom(JsonParser.asString(json['kind'])),
      description: JsonParser.asString(json['description']),
      options: JsonParser.asList(json['options'], FilterOption.fromJson),
      params: json['params'] is List
          ? (json['params'] as List).map((p) => '$p').toList()
          : const [],
    );
  }

  static FilterKind _kindFrom(String raw) {
    switch (raw) {
      case 'select':
        return FilterKind.select;
      case 'datetime_range':
        return FilterKind.datetimeRange;
      default:
        return FilterKind.unsupported;
    }
  }

  String get title => label.trim().isEmpty ? humanise(key) : label.trim();

  /// Key -> title, for a backend that has not sent a label yet.
  static String humanise(String key) {
    final String spaced = key.replaceAll('_id', '').replaceAll('_', ' ');
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String get lowerBoundParam => params.isNotEmpty ? params.first : '${key}_gte';

  String get upperBoundParam => params.length > 1 ? params[1] : '${key}_lte';

  @override
  List<Object?> get props => [key, label, kind, description, options, params];
}

/// What a sort is ordering, which decides how its two directions are worded:
/// a date reads newest/oldest, a number highest/lowest, text A-Z.
enum SortKind { date, number, text }

class ClientSort extends Equatable {
  final String key;
  final String label;
  final String description;

  const ClientSort({required this.key, this.label = '', this.description = ''});

  factory ClientSort.fromJson(Map<String, dynamic> json) {
    return ClientSort(
      key: JsonParser.asString(json['sort']),
      label: JsonParser.asString(json['label']),
      description: JsonParser.asString(json['description']),
    );
  }

  String get title =>
      label.trim().isEmpty ? ClientFilter.humanise(key) : label.trim();

  /// The backend does not type its sorts, so the kind is read off the key.
  /// An unrecognised key falls back to text, whose A-Z wording is the least
  /// wrong thing to say about an unknown field.
  SortKind get kind {
    final String needle = key.toLowerCase();

    for (final String token in _DATE_TOKENS) {
      if (needle.contains(token)) return SortKind.date;
    }
    for (final String token in _NUMBER_TOKENS) {
      if (needle.contains(token)) return SortKind.number;
    }
    return SortKind.text;
  }

  static const List<String> _DATE_TOKENS = [
    'created',
    'updated',
    'date',
    '_at',
    'time',
  ];

  static const List<String> _NUMBER_TOKENS = [
    'price',
    'amount',
    'total',
    'count',
    'quantity',
    'weight',
  ];

  @override
  List<Object?> get props => [key, label, description];
}
