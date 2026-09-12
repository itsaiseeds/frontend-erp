import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/auth/data/models/auth_session.dart';

void main() {
  group('AuthSession.fromJson', () {
    test('reads the nested user object returned by the login endpoint', () {
      final session = AuthSession.fromJson({
        'token': 'abc123',
        'user': {
          'id': 7,
          'name': 'Asha Patel',
          'phone_number': '9876543210',
          'role': 'salesperson',
        },
      });

      expect(session.userId, 7);
      expect(session.name, 'Asha Patel');
      expect(session.phoneNumber, '9876543210');
      expect(session.role, 'salesperson');
    });

    test('falls back to a flat payload when there is no user envelope', () {
      final session = AuthSession.fromJson({
        'id': 3,
        'name': 'Ravi Kumar',
        'phone_number': '9000000000',
        'role': 'salesperson',
      });

      expect(session.userId, 3);
      expect(session.name, 'Ravi Kumar');
    });

    test('coerces a string id and tolerates missing fields', () {
      final session = AuthSession.fromJson({
        'user': {'id': '42'},
      });

      expect(session.userId, 42);
      expect(session.name, '');
      expect(session.phoneNumber, '');
      expect(session.role, '');
    });

    test('falls back to zero when the id is not parseable', () {
      final session = AuthSession.fromJson({
        'user': {'id': 'not-a-number'},
      });

      expect(session.userId, 0);
    });
  });
}
