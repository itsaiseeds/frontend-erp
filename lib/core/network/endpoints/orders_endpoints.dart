class OrdersEndpoints {
  OrdersEndpoints._();

  static const String _base = '/android/api/v1';

  static const String list = '$_base/get-orders';

  static String challan(String orderPublicId) =>
      '$_base/get-challan/$orderPublicId';
}
