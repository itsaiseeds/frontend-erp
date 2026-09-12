import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/network/api_client.dart';
import 'package:frontend_erp/core/network/api_exception.dart';
import 'package:frontend_erp/core/network/endpoints/auth_endpoints.dart';
import 'package:frontend_erp/core/services/storage_service.dart';
import 'package:frontend_erp/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;
  final Object body;
  RequestOptions? lastRequest;

  _FakeAdapter({required this.statusCode, required this.body});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      _encode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static String _encode(Object body) =>
      body is String ? body : _jsonEncode(body);

  static String _jsonEncode(Object body) {
    if (body is Map) {
      final entries = body.entries
          .map((e) => '"${e.key}":${_encodeValue(e.value)}')
          .join(',');
      return '{$entries}';
    }
    return '$body';
  }

  static String _encodeValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is Map) return _jsonEncode(value);
    if (value is num || value is bool) return '$value';
    return 'null';
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _clientWith(_FakeAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.httpClientAdapter = adapter;
  return ApiClient(dio: dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clearSession();
  });

  test('a successful login persists the token and the profile', () async {
    final adapter = _FakeAdapter(
      statusCode: 200,
      body: {
        'token': 'tok-123',
        'user': {
          'id': 5,
          'name': 'Asha Patel',
          'phone_number': '9876543210',
          'role': 'salesperson',
        },
      },
    );
    final repository = AuthRepository(apiClient: _clientWith(adapter));

    final session = await repository.login(
      phoneNumber: '9876543210',
      otp: '123456',
    );

    expect(session.name, 'Asha Patel');
    expect(await StorageService.getAuthToken(), 'tok-123');
    expect(await StorageService.getUserRole(), 'salesperson');
    expect(adapter.lastRequest?.path, AuthEndpoints.login);
  });

  test('the backend detail message survives as the thrown message', () async {
    final adapter = _FakeAdapter(
      statusCode: 400,
      body: {'detail': 'Invalid phone number or TOTP code.'},
    );
    final repository = AuthRepository(apiClient: _clientWith(adapter));

    expect(
      () => repository.login(phoneNumber: '9999999999', otp: '000000'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Invalid phone number or TOTP code.',
        ),
      ),
    );
  });

  test('a failed login stores no token', () async {
    final adapter = _FakeAdapter(
      statusCode: 400,
      body: {'detail': 'Invalid phone number or TOTP code.'},
    );
    final repository = AuthRepository(apiClient: _clientWith(adapter));

    await expectLater(
      repository.login(phoneNumber: '9999999999', otp: '000000'),
      throwsA(isA<ApiException>()),
    );

    expect(await StorageService.getAuthToken(), isNull);
  });

  test(
    'a 200 without a token is rejected rather than half-persisted',
    () async {
      final adapter = _FakeAdapter(
        statusCode: 200,
        body: {
          'user': {'id': 5, 'name': 'Asha Patel'},
        },
      );
      final repository = AuthRepository(apiClient: _clientWith(adapter));

      await expectLater(
        repository.login(phoneNumber: '9876543210', otp: '123456'),
        throwsA(isA<ApiException>()),
      );

      expect(await StorageService.getAuthToken(), isNull);
    },
  );

  test('readStoredSession returns null when no token is stored', () async {
    final adapter = _FakeAdapter(statusCode: 200, body: {});
    final repository = AuthRepository(apiClient: _clientWith(adapter));

    expect(await repository.readStoredSession(), isNull);
  });

  test(
    'an expired token clears the stored session on reauthenticate',
    () async {
      await StorageService.saveAuthToken('stale-token');
      await StorageService.saveUserName('Asha Patel');

      final adapter = _FakeAdapter(
        statusCode: 401,
        body: {'detail': 'Token has expired.'},
      );
      final repository = AuthRepository(apiClient: _clientWith(adapter));

      expect(await repository.reauthenticate(), isNull);
      expect(await StorageService.getAuthToken(), isNull);
    },
  );
}
