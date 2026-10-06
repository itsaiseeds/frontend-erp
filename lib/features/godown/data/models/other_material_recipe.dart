import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'godown_refs.dart';

/// One other-material recipe (`OMR-…`): how much of a material a given
/// packet weight of a product consumes. Master data here -- admin-created,
/// read-only to the godown.
class OtherMaterialRecipe extends Equatable {
  final String publicId;
  final GodownProductRef product;
  final GodownMaterialTypeRef materialType;
  final String packetWeight;
  final String quantity;

  const OtherMaterialRecipe({
    required this.publicId,
    this.product = const GodownProductRef(),
    this.materialType = const GodownMaterialTypeRef(),
    this.packetWeight = '',
    this.quantity = '',
  });

  factory OtherMaterialRecipe.fromJson(Map<String, dynamic> json) {
    return OtherMaterialRecipe(
      publicId: JsonParser.asString(json['public_id']),
      product:
          GodownJson.refOf(json['product'], GodownProductRef.fromJson) ??
          const GodownProductRef(),
      materialType:
          GodownJson.refOf(
            json['material_type'],
            GodownMaterialTypeRef.fromJson,
          ) ??
          const GodownMaterialTypeRef(),
      packetWeight: JsonParser.asString(json['packet_weight']),
      quantity: JsonParser.asString(json['quantity']),
    );
  }

  /// "Product - Material (2.000)" -- what the booking picker shows and
  /// searches on, mirroring the admin recipe picker.
  String get label {
    final List<String> parts = [
      if (product.name.trim().isNotEmpty) product.name,
      if (materialType.name.trim().isNotEmpty) materialType.name,
    ];
    final String head = parts.isEmpty ? publicId : parts.join(' - ');
    if (packetWeight.trim().isEmpty) return head;
    return '$head ($packetWeight)';
  }

  @override
  List<Object?> get props => [
    publicId,
    product,
    materialType,
    packetWeight,
    quantity,
  ];
}
