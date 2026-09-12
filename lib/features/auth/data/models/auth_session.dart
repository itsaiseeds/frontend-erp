import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

class AuthSession extends Equatable {
  final int userId;
  final String name;
  final String phoneNumber;
  final String role;

  const AuthSession({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.role,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final Map<String, dynamic> userMap = user is Map
        ? Map<String, dynamic>.from(user)
        : Map<String, dynamic>.from(json);

    return AuthSession(
      userId: JsonParser.asInt(userMap['id']),
      name: JsonParser.asString(userMap['name']),
      phoneNumber: JsonParser.asString(userMap['phone_number']),
      role: JsonParser.asString(userMap['role']),
    );
  }

  @override
  List<Object?> get props => [userId, name, phoneNumber, role];
}
