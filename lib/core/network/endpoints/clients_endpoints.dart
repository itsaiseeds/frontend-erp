class ClientsEndpoints {
  ClientsEndpoints._();

  static const String _base = '/android/api/v1';

  static const String create = '$_base/create-client';
  static const String update = '$_base/update-client';
  static const String list = '$_base/get-clients';

  static String detail(String publicId) => '$_base/client/$publicId';
}
