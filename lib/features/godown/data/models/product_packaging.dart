import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// The product a packaging belongs to, as the godown's packaging list needs
/// it: usability (a frozen product cannot be counted) plus the picture the
/// app labels the row with. Distinct from [GodownProductRef] in
/// `godown_refs.dart`, which carries neither -- composing that type here
/// would mean re-wrapping it just to bolt two fields on, so this stands on
/// its own instead.
class GodownPackagingProductRef extends Equatable {
  final String publicId;
  final String name;
  final bool isUsable;
  final String imageUrl;

  const GodownPackagingProductRef({
    this.publicId = '',
    this.name = '',
    this.isUsable = true,
    this.imageUrl = '',
  });

  factory GodownPackagingProductRef.fromJson(Map<String, dynamic> json) {
    return GodownPackagingProductRef(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
      isUsable: JsonParser.asBool(json['is_usable']),
      imageUrl: JsonParser.asString(json['image_url']),
    );
  }

  @override
  List<Object?> get props => [publicId, name, isUsable, imageUrl];
}

/// A single row from `godown/product-packagings`: the master data for one
/// packaging -- how many packets of what weight make up one sealed bag, and
/// what it sells for. `packets` here is NOT a day's count; it is the fixed
/// "packets per bag" figure the count screens use to label a row.
class GodownProductPackaging extends Equatable {
  final String publicId;
  final GodownPackagingProductRef product;
  final String packetWeight;
  final int packets;
  final String totalWeight;
  final String sellingPrice;

  const GodownProductPackaging({
    this.publicId = '',
    this.product = const GodownPackagingProductRef(),
    this.packetWeight = '',
    this.packets = 0,
    this.totalWeight = '',
    this.sellingPrice = '',
  });

  factory GodownProductPackaging.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];

    return GodownProductPackaging(
      publicId: JsonParser.asString(json['public_id']),
      product: product is Map
          ? GodownPackagingProductRef.fromJson(
              Map<String, dynamic>.from(product),
            )
          : const GodownPackagingProductRef(),
      packetWeight: JsonParser.asString(json['packet_weight']),
      packets: JsonParser.asInt(json['packets']),
      totalWeight: JsonParser.asString(json['total_weight']),
      sellingPrice: JsonParser.asString(json['selling_price']),
    );
  }

  String get productName => product.name;

  String get productPublicId => product.publicId;

  /// Row label, e.g. "SAI-33 (40pkts x 1.1kg)" -- product name, packets per
  /// bag and packet weight from the packaging master data.
  String get label =>
      '$productName ($packets'
      'pkts x ${packetWeight}kg)';

  @override
  List<Object?> get props => [
    publicId,
    product,
    packetWeight,
    packets,
    totalWeight,
    sellingPrice,
  ];
}
