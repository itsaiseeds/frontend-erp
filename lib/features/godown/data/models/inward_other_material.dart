import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'godown_refs.dart';

/// The recipe a lot was booked against. The lot nests only id and name for
/// the material type, so this stays separate from the full recipe row.
class InwardOtherRecipeRef extends Equatable {
  final String publicId;
  final GodownProductRef product;
  final GodownMaterialTypeRef materialType;
  final String packetWeight;

  const InwardOtherRecipeRef({
    this.publicId = '',
    this.product = const GodownProductRef(),
    this.materialType = const GodownMaterialTypeRef(),
    this.packetWeight = '',
  });

  factory InwardOtherRecipeRef.fromJson(Map<String, dynamic> json) {
    return InwardOtherRecipeRef(
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
    );
  }

  @override
  List<Object?> get props => [publicId, product, materialType, packetWeight];
}

/// One inward other-material lot (`IO-…`).
///
/// Nothing on it is writable once booked -- the effective date was stamped
/// with today at booking, and party / recipe / quantity are immutable. A
/// mistyped booking is corrected by deleting and re-booking.
class InwardOtherMaterial extends Equatable {
  final String publicId;
  final InwardOtherRecipeRef recipe;
  final GodownPartyRef party;
  final GodownReturnOrderRef? returnOrder;
  final String quantity;
  final DateTime? effectiveDate;
  final GodownActorRef? createdBy;

  const InwardOtherMaterial({
    required this.publicId,
    this.recipe = const InwardOtherRecipeRef(),
    this.party = const GodownPartyRef(),
    this.returnOrder,
    this.quantity = '',
    this.effectiveDate,
    this.createdBy,
  });

  factory InwardOtherMaterial.fromJson(Map<String, dynamic> json) {
    return InwardOtherMaterial(
      publicId: JsonParser.asString(json['public_id']),
      recipe:
          GodownJson.refOf(json['recipe'], InwardOtherRecipeRef.fromJson) ??
          const InwardOtherRecipeRef(),
      party:
          GodownJson.refOf(json['party'], GodownPartyRef.fromJson) ??
          const GodownPartyRef(),
      returnOrder: GodownJson.refOf(
        json['return_order'],
        GodownReturnOrderRef.fromJson,
      ),
      quantity: JsonParser.asString(json['quantity']),
      effectiveDate: GodownJson.dateOf(json['effective_date']),
      createdBy: GodownJson.refOf(json['created_by'], GodownActorRef.fromJson),
    );
  }

  /// A lot an accepted return booked is owned by that return.
  bool get isReturnLot => returnOrder != null;

  bool get canDelete => !isReturnLot;

  String get productName => recipe.product.name;

  String get materialTypeName => recipe.materialType.name;

  @override
  List<Object?> get props => [
    publicId,
    recipe,
    party,
    returnOrder,
    quantity,
    effectiveDate,
    createdBy,
  ];
}
