import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

class AuthSession extends Equatable {
  final int userId;
  final String name;
  final String phoneNumber;
  final String role;

  /// A user can hold either role, so the server sends both flags rather
  /// than one enum -- routing reads these, never ``role``.
  final bool isSalesPerson;
  final bool isGodownManager;

  const AuthSession({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.isSalesPerson = false,
    this.isGodownManager = false,
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
      isSalesPerson: userMap['is_sales_person'] == true,
      isGodownManager: userMap['is_godown_manager'] == true,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    phoneNumber,
    role,
    isSalesPerson,
    isGodownManager,
  ];
}
