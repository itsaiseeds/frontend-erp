class GodownEndpoints {
  GodownEndpoints._();

  static const String _base = '/android/api/v1/godown';

  static const String rawMaterialStock = '$_base/raw-material-stock';

  /// v2: adds ``?group_by=configuration`` (one line per product, packet
  /// weight and material type) on top of v1's per-material-type lines. v1
  /// never gained that query param, so this stays pinned to v2 regardless of
  /// the rest of this class.
  static const String otherMaterialStock =
      '/android/api/v2/godown/other-material-stock';
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
  static const String rawMaterialWastes = '$_base/raw-material-wastes';
  static const String transferProduct = '$_base/transfer-product';

  static String inwardRawMaterial(String publicId) =>
      '$_base/inward-raw-material/$publicId';

  static String inwardOtherMaterial(String publicId) =>
      '$_base/inward-other-material/$publicId';

  static String rawMaterialWaste(String publicId) =>
      '$_base/raw-material-waste/$publicId';
}
