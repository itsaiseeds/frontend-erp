class ClientsEndpoints {
  ClientsEndpoints._();

  static const String _base = '/android/api/v1';

  static const String create = '$_base/create-client';
  static const String update = '$_base/update-client';
  static const String list = '$_base/get-clients';

  static String detail(String publicId) => '$_base/client/$publicId';

  static const String addresses = '$_base/utilities/client-addresses';
  static const String transportAgencies =
      '$_base/utilities/client-transport-agencies';

  /// Both link pickers are scoped to one client by this query param.
  static const String CLIENT_PUBLIC_ID_PARAM = 'client_public_id';

  /// Admin-only: scopes the client list and link pickers to another sales
  /// person's clients instead of the caller's own.
  static const String SALES_PERSON_ID_PARAM = 'sales_person_id';
}
