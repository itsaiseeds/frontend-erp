import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

class TransportAgency extends Equatable {
  final String name;
  final bool isPrimary;

  const TransportAgency({required this.name, this.isPrimary = false});

  factory TransportAgency.fromJson(Map<String, dynamic> json) {
    return TransportAgency(
      name: JsonParser.asString(json['name']),
      isPrimary: JsonParser.asBool(json['is_primary']),
    );
  }

  Map<String, dynamic> toWriteJson() => {'name': name, 'is_primary': isPrimary};

  @override
  List<Object?> get props => [name, isPrimary];
}
