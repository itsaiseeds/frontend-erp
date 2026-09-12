class AuthEndpoints {
  AuthEndpoints._();

  static const String _base = '/android/api/v1/auth';

  static const String login = '$_base/login';
  static const String logout = '$_base/logout';
  static const String reauthenticate = '$_base/reauthenticate';
}
