import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'godown_refs.dart';

/// One written-off quantity of a product's raw material (``WS-…``).
///
/// Godown managers add, edit and delete these rows directly -- unlike inward
/// lots, there is no admin verification step, since waste has nothing left to
/// verify: the material is simply gone.
class RawMaterialWaste extends Equatable {
  final String publicId;
  final GodownProductRef product;
  final String quantityKg;
  final String reason;
  final DateTime? createdAt;
  final GodownActorRef? createdBy;

  const RawMaterialWaste({
    this.publicId = '',
    this.product = const GodownProductRef(),
    this.quantityKg = '',
    this.reason = '',
    this.createdAt,
    this.createdBy,
  });

  factory RawMaterialWaste.fromJson(Map<String, dynamic> json) {
    return RawMaterialWaste(
      publicId: JsonParser.asString(json['public_id']),
      product:
          GodownJson.refOf(json['product'], GodownProductRef.fromJson) ??
          const GodownProductRef(),
      quantityKg: JsonParser.asString(json['quantity_kg']),
      reason: JsonParser.asString(json['reason']),
      createdAt: DateTime.tryParse(JsonParser.asString(json['created_at'])),
      createdBy: GodownJson.refOf(json['created_by'], GodownActorRef.fromJson),
    );
  }

  bool matchesSearch(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return product.name.toLowerCase().contains(needle) ||
        reason.toLowerCase().contains(needle) ||
        publicId.toLowerCase().contains(needle);
  }

  @override
  List<Object?> get props => [
    publicId,
    product,
    quantityKg,
    reason,
    createdAt,
    createdBy,
  ];
}
