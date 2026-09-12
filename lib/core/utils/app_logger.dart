import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static const String _network = 'network';
  static const String _auth = 'auth';
  static const String _session = 'session';

  static const String _redacted = '***';

  static const Set<String> _sensitiveKeys = {
    'otp',
    'token',
    'password',
    'authorization',
    'x-csrftoken',
    'cookie',
    'set-cookie',
  };

  static bool get _isEnabled => !kReleaseMode;

  static void request(String method, String url, {Object? body}) {
    if (!_isEnabled) return;
    final String suffix = body == null ? '' : ' body=${_sanitise(body)}';
    developer.log('--> $method $url$suffix', name: _network);
  }

  static void response(String method, String url, int? statusCode) {
    if (!_isEnabled) return;
    developer.log('<-- $statusCode $method $url', name: _network);
  }

  static void networkError(String method, String url, Object error) {
    if (!_isEnabled) return;
    developer.log('<-- FAILED $method $url: $error', name: _network);
  }

  static void auth(String message) {
    if (!_isEnabled) return;
    developer.log(message, name: _auth);
  }

  static void session(String message) {
    if (!_isEnabled) return;
    developer.log(message, name: _session);
  }

  @visibleForTesting
  static String sanitiseForTest(Object body) => _sanitise(body);

  static String _sanitise(Object body) {
    try {
      return jsonEncode(_redact(body));
    } catch (_) {
      return _redacted;
    }
  }

  static Object? _redact(Object? value) {
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(
          '$key',
          _sensitiveKeys.contains('$key'.toLowerCase())
              ? _redacted
              : _redact(nested),
        ),
      );
    }
    if (value is List) return value.map(_redact).toList();
    if (value is num || value is bool || value == null) return value;
    return '$value';
  }
}
