class ReturnOrdersEndpoints {
  ReturnOrdersEndpoints._();

  static const String _base = '/android/api/v1';

  static const String list = '$_base/get-return-orders';

  /// Prefill (GET) and create (POST) for one order.
  ///
  /// v2: an order may carry any number of live returns, capped only by what
  /// the challan actually dispatched; `GET` sends every live return
  /// (`return_orders`, newest first) instead of the single newest one, and
  /// `POST` allows creating another while one is already live. v1 is kept
  /// exactly as it was for older builds, so this app always targets v2.
  static String forOrder(String orderPublicId) =>
      '/android/api/v2/return-order/$orderPublicId';
}
