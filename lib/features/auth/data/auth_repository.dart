import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/auth_endpoints.dart';
import '../../../core/services/session_guard.dart';
import '../../../core/services/storage_service.dart';
import 'models/auth_session.dart';

class AuthRepository {
  final ApiClient _apiClient;

  const AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AuthSession> login({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      AuthEndpoints.login,
      body: {'phone_number': phoneNumber, 'otp': otp},
    );

    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    final Map<String, dynamic> payload = Map<String, dynamic>.from(response);
    final dynamic token = payload['token'];

    if (token is! String || token.isEmpty) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }

    final session = AuthSession.fromJson(payload);

    await StorageService.saveAuthToken(token);
    await _persistSession(session);

    return session;
  }

  Future<AuthSession?> readStoredSession() async {
    final String? token = await StorageService.getAuthToken();
    if (token == null || token.isEmpty) return null;

    return AuthSession(
      userId: await StorageService.getUserId() ?? 0,
      name: await StorageService.getUserName() ?? '',
      phoneNumber: await StorageService.getUserPhoneNumber() ?? '',
      role: await StorageService.getUserRole() ?? '',
    );
  }

  Future<AuthSession?> reauthenticate() async {
    final String? token = await StorageService.getAuthToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _apiClient.get(AuthEndpoints.reauthenticate);
      if (response is! Map) return null;

      final session = AuthSession.fromJson(Map<String, dynamic>.from(response));
      await _persistSession(session);
      return session;
    } on ApiException {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(AuthEndpoints.logout);
    } catch (_) {
      return;
    } finally {
      await SessionGuard.endSession();
    }
  }

  Future<void> clearSession() => SessionGuard.endSession();

  Future<void> _persistSession(AuthSession session) async {
    await StorageService.saveUserId(session.userId);
    await StorageService.saveUserName(session.name);
    await StorageService.saveUserPhoneNumber(session.phoneNumber);
    await StorageService.saveUserRole(session.role);
  }
}
