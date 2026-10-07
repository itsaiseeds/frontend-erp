class LabEndpoints {
  LabEndpoints._();

  static const String _base = '/android/api/v1/lab';

  static const String pendingLots = '$_base/pending-lots';
  static const String labTestings = '$_base/lab-testings';

  static String labTesting(String publicId) =>
      '$_base/lab-testing/$publicId';
}
