class UtilitiesEndpoints {
  UtilitiesEndpoints._();

  static const String _base = '/android/api/v1/utilities';

  static const String cities = '$_base/cities';
  static const String states = '$_base/states';
  static const String countries = '$_base/countries';
  static const String crops = '$_base/crops';
  static const String products = '$_base/products';
  static const String parties = '$_base/parties';
  static const String otherMaterialTypes = '$_base/other-material-types';

  /// Admin-only: sales persons an admin may book an order for.
  static const String salesPersons = '$_base/sales-persons';
}
