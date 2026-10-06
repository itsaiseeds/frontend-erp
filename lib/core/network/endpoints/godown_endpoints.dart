class GodownEndpoints {
  GodownEndpoints._();

  static const String _base = '/android/api/v1/godown';

  static const String rawMaterialStock = '$_base/raw-material-stock';
  static const String otherMaterialStock = '$_base/other-material-stock';
  static const String inwardRawMaterials = '$_base/inward-raw-materials';
  static const String inwardOtherMaterials = '$_base/inward-other-materials';
  static const String otherMaterialRecipes = '$_base/other-material-recipes';
  static const String checkTodaysInventory = '$_base/check-todays-inventory';
  static const String productPackagings = '$_base/product-packagings';
  static const String updateBagStock = '$_base/update-bag-stock';
  static const String updateSamplePacketStock =
      '$_base/update-sample-packet-stock';
  static const String bagStock = '$_base/bag-stock';
  static const String samplePacketStock = '$_base/sample-packet-stock';

  static String inwardRawMaterial(String publicId) =>
      '$_base/inward-raw-material/$publicId';

  static String inwardOtherMaterial(String publicId) =>
      '$_base/inward-other-material/$publicId';
}
