import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/utils/app_logger.dart';

void main() {
  group('AppLogger redaction', () {
    test('the otp is masked in a login body', () {
      final line = AppLogger.sanitiseForTest({
        'phone_number': '9876543210',
        'otp': '123456',
      });

      expect(line.contains('123456'), isFalse);
      expect(line.contains('***'), isTrue);
    });

    test('the phone number survives so the call stays debuggable', () {
      final line = AppLogger.sanitiseForTest({
        'phone_number': '9876543210',
        'otp': '123456',
      });

      expect(line.contains('9876543210'), isTrue);
    });

    test('a bearer token value is masked', () {
      final line = AppLogger.sanitiseForTest({
        'token': '9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b',
      });

      expect(
        line.contains('9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b'),
        isFalse,
      );
    });

    test('sensitive keys are matched case-insensitively', () {
      final line = AppLogger.sanitiseForTest({
        'OTP': '123456',
        'Authorization': 'Token abc123',
      });

      expect(line.contains('123456'), isFalse);
      expect(line.contains('abc123'), isFalse);
    });

    test('a nested sensitive value is masked too', () {
      final line = AppLogger.sanitiseForTest({
        'user': {'name': 'Asha', 'token': 'secret-value'},
      });

      expect(line.contains('secret-value'), isFalse);
      expect(line.contains('Asha'), isTrue);
    });

    test('sensitive values inside a list are masked', () {
      final line = AppLogger.sanitiseForTest([
        {'otp': '111111'},
        {'otp': '222222'},
      ]);

      expect(line.contains('111111'), isFalse);
      expect(line.contains('222222'), isFalse);
    });

    test('an unencodable body degrades to a mask rather than throwing', () {
      final line = AppLogger.sanitiseForTest(Object());

      expect(line, isNotEmpty);
    });
  });
}
