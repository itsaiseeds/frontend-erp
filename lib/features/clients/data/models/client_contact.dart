import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

class ClientContact extends Equatable {
  final String name;
  final String phoneNumber;
  final String role;
  final bool isPrimary;

  const ClientContact({
    required this.name,
    required this.phoneNumber,
    this.role = '',
    this.isPrimary = false,
  });

  factory ClientContact.fromJson(Map<String, dynamic> json) {
    return ClientContact(
      name: JsonParser.asString(json['name']),
      phoneNumber: JsonParser.asString(json['phone_number']),
      role: JsonParser.asString(json['role']),
      isPrimary: JsonParser.asBool(json['is_primary']),
    );
  }

  Map<String, dynamic> toWriteJson() => {
    'name': name,
    'phone_number': phoneNumber,
    'role': role,
    'is_primary': isPrimary,
  };

  @override
  List<Object?> get props => [name, phoneNumber, role, isPrimary];
}
