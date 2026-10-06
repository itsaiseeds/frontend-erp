class FieldTripsEndpoints {
  FieldTripsEndpoints._();

  static const String _base = '/android/api/v1';

  static const String list = '$_base/get-field-trips';
  static const String create = '$_base/create-field-trip';
  static const String createFarmerVisit = '$_base/create-farmer-visit';

  static String edit(String publicId) => '$_base/edit-field-trip/$publicId';

  static String start(String publicId) => '$_base/start-field-trip/$publicId';

  static String end(String publicId) => '$_base/end-field-trip/$publicId';

  static String delete(String publicId) =>
      '$_base/delete-field-trip/$publicId';

  static String editFarmerVisit(String publicId) =>
      '$_base/edit-farmer-visit/$publicId';

  static String farmerVisits(String publicId) =>
      '$_base/field-trip-farmer-visits/$publicId';
}
