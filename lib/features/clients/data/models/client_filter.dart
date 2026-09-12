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
  final FilterKind kind;
  final String description;
  final List<FilterOption> options;
  final List<String> params;

  const ClientFilter({
    required this.key,
    required this.kind,
    this.description = '',
    this.options = const [],
    this.params = const [],
  });

  factory ClientFilter.fromJson(Map<String, dynamic> json) {
    return ClientFilter(
      key: JsonParser.asString(json['filter']),
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

  String get lowerBoundParam => params.isNotEmpty ? params.first : '${key}_gte';

  String get upperBoundParam => params.length > 1 ? params[1] : '${key}_lte';

  @override
  List<Object?> get props => [key, kind, description, options, params];
}

class ClientSort extends Equatable {
  final String key;
  final String description;

  const ClientSort({required this.key, this.description = ''});

  factory ClientSort.fromJson(Map<String, dynamic> json) {
    return ClientSort(
      key: JsonParser.asString(json['sort']),
      description: JsonParser.asString(json['description']),
    );
  }

  @override
  List<Object?> get props => [key, description];
}
