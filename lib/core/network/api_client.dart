import 'dart:async';

import 'package:dio/dio.dart';
import '../constants/app_strings.dart';
import '../services/session_guard.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'endpoints/auth_endpoints.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({Dio? dio}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.timeout,
            receiveTimeout: ApiConfig.timeout,
            sendTimeout: ApiConfig.timeout,
            headers: ApiConfig.defaultHeaders,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isPublicRequest(options.path)) {
            final String? token = await StorageService.getAuthToken();
            if (token != null && token.isNotEmpty) {
              options.headers[ApiConfig.AUTH_HEADER] =
                  '${ApiConfig.AUTH_SCHEME} $token';
            }
          }
          AppLogger.request(
            options.method,
            options.uri.toString(),
            body: options.data,
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.response(
            response.requestOptions.method,
            response.requestOptions.uri.toString(),
            response.statusCode,
          );
          return handler.next(response);
        },
        onError: (err, handler) async {
          AppLogger.networkError(
            err.requestOptions.method,
            err.requestOptions.uri.toString(),
            err.response?.statusCode ?? err.type.name,
          );
          if (err.response?.statusCode == _unauthorizedStatus &&
              !_isPublicRequest(err.requestOptions.path)) {
            await SessionGuard.endSession();
          }
          return handler.next(err);
        },
      ),
    );
  }

  static const int _unauthorizedStatus = 401;
  static const int _forbiddenStatus = 403;
  static const int _notFoundStatus = 404;
  static const int _rateLimitedStatus = 429;

  static bool _isPublicRequest(String path) =>
      path.endsWith(AuthEndpoints.login);

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    try {
      final response = await _dio.put(endpoint, data: body);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    try {
      final response = await _dio.patch(endpoint, data: body);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {dynamic body}) async {
    try {
      final response = await _dio.delete(endpoint, data: body);
      return _processResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ApiProbeResult> probe(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return ApiProbeResult(
        statusCode: response.statusCode ?? 0,
        data: response.data,
      );
    } on DioException catch (e) {
      final int? statusCode = e.response?.statusCode;
      if (statusCode == null) return const ApiProbeResult.unreachable();
      return ApiProbeResult(statusCode: statusCode, data: e.response?.data);
    } catch (_) {
      return const ApiProbeResult.unreachable();
    }
  }

  dynamic _processResponse(Response response) {
    final statusCode = response.statusCode;
    if (statusCode != null && statusCode >= 200 && statusCode < 300) {
      return response.data;
    }
    if (statusCode == _unauthorizedStatus &&
        !_isPublicRequest(response.requestOptions.path)) {
      unawaited(SessionGuard.endSession());
    }
    final String message = _extractErrorMessage(response.data, statusCode);
    AppLogger.networkError(
      response.requestOptions.method,
      response.requestOptions.uri.toString(),
      '$statusCode $message',
    );
    throw ApiException(statusCode: statusCode ?? 500, message: message);
  }

  ApiException _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final int? statusCode = response.statusCode;
      return ApiException(
        statusCode: statusCode ?? 500,
        message: _extractErrorMessage(response.data, statusCode),
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.unknown(AppStrings.ERROR_TIMEOUT);
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return ApiException.unknown(AppStrings.ERROR_NETWORK);
      case DioExceptionType.cancel:
        return ApiException.unknown(AppStrings.ERROR_CANCELLED);
      default:
        return ApiException.unknown(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  String _extractErrorMessage(dynamic data, [int? statusCode]) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      final message = data['message'];
      if (message is List && message.isNotEmpty) return message.join('\n');
      if (message is String && message.isNotEmpty) return message;
      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;
      final String? fieldError = _extractFieldError(data);
      if (fieldError != null) return fieldError;
    }
    return _fallbackMessageFor(statusCode);
  }

  static String? _extractFieldError(Map data) {
    for (final dynamic value in data.values) {
      if (value is String && value.isNotEmpty) return value;
      if (value is List) {
        final Iterable<String> messages = value.whereType<String>().where(
          (entry) => entry.isNotEmpty,
        );
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }
    return null;
  }

  String _fallbackMessageFor(int? statusCode) {
    switch (statusCode) {
      case _forbiddenStatus:
        return AppStrings.ERROR_FORBIDDEN;
      case _notFoundStatus:
        return AppStrings.ERROR_NOT_FOUND;
      case _rateLimitedStatus:
        return AppStrings.ERROR_RATE_LIMITED;
    }
    if (statusCode != null && statusCode >= 500) {
      return AppStrings.ERROR_SERVER;
    }
    return AppStrings.SOMETHING_WENT_WRONG;
  }
}

class ApiProbeResult {
  final int statusCode;
  final dynamic data;

  const ApiProbeResult({required this.statusCode, this.data});

  const ApiProbeResult.unreachable() : statusCode = 0, data = null;

  bool get isUnreachable => statusCode == 0;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  bool get isUnauthorized => statusCode == 401;
}
