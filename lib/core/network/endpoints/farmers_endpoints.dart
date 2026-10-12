class FarmersEndpoints {
  FarmersEndpoints._();

  static const String _base = '/android/api/v1';

  static const String list = '$_base/farmers';
  static const String create = '$_base/farmers';

  static String detail(String publicId) => '$_base/farmer/$publicId';
}
