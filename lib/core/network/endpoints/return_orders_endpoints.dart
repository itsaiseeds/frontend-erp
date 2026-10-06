class ReturnOrdersEndpoints {
  ReturnOrdersEndpoints._();

  static const String _base = '/android/api/v1';

  static const String list = '$_base/get-return-orders';

  /// Prefill (GET) and create (POST) for one order.
  static String forOrder(String orderPublicId) =>
      '$_base/return-order/$orderPublicId';
}
