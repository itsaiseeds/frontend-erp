import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'godown_refs.dart';

/// One product's incoming raw-material position, all figures in kilograms.
class RawMaterialStockLine extends Equatable {
  final String productPublicId;
  final String name;
  final bool isUsable;
  final String incomingKg;
  final String packedKg;
  final String wastedKg;
  final String availableKg;
  final String rejectedKg;

  const RawMaterialStockLine({
    this.productPublicId = '',
    this.name = '',
    this.isUsable = true,
    this.incomingKg = '',
    this.packedKg = '',
    this.wastedKg = '',
    this.availableKg = '',
    this.rejectedKg = '',
  });

  factory RawMaterialStockLine.fromJson(Map<String, dynamic> json) {
    return RawMaterialStockLine(
      productPublicId: JsonParser.asString(json['product']),
      name: JsonParser.asString(json['name']),
      isUsable: JsonParser.asBool(json['is_usable']),
      incomingKg: JsonParser.asString(json['incoming_kg']),
      packedKg: JsonParser.asString(json['packed_kg']),
      wastedKg: JsonParser.asString(json['wasted_kg']),
      availableKg: JsonParser.asString(json['available_kg']),
      rejectedKg: JsonParser.asString(json['rejected_kg']),
    );
  }

  num get availableValue => num.tryParse(availableKg.trim()) ?? 0;

  @override
  List<Object?> get props => [
    productPublicId,
    name,
    isUsable,
    incomingKg,
    packedKg,
    wastedKg,
    availableKg,
    rejectedKg,
  ];
}

class RawMaterialStock extends Equatable {
  final DateTime? asOf;
  final List<RawMaterialStockLine> lines;

  const RawMaterialStock({this.asOf, this.lines = const []});

  factory RawMaterialStock.fromJson(Map<String, dynamic> json) {
    return RawMaterialStock(
      asOf: GodownJson.dateOf(json['as_of']),
      lines: JsonParser.asList(json['lines'], RawMaterialStockLine.fromJson),
    );
  }

  @override
  List<Object?> get props => [asOf, lines];
}

/// One material type's on-hand position, in that type's own unit. Negative
/// when the packet counts outrun the recorded inward lots.
class OtherMaterialStockLine extends Equatable {
  final GodownMaterialTypeRef materialType;
  final String onHand;

  const OtherMaterialStockLine({
    this.materialType = const GodownMaterialTypeRef(),
    this.onHand = '',
  });

  factory OtherMaterialStockLine.fromJson(Map<String, dynamic> json) {
    return OtherMaterialStockLine(
      materialType:
          GodownJson.refOf(
            json['material_type'],
            GodownMaterialTypeRef.fromJson,
          ) ??
          const GodownMaterialTypeRef(),
      onHand: JsonParser.asString(json['on_hand']),
    );
  }

  num get onHandValue => num.tryParse(onHand.trim()) ?? 0;

  bool get isShort => onHandValue < 0;

  @override
  List<Object?> get props => [materialType, onHand];
}

class OtherMaterialStock extends Equatable {
  final DateTime? asOf;
  final List<OtherMaterialStockLine> lines;

  const OtherMaterialStock({this.asOf, this.lines = const []});

  factory OtherMaterialStock.fromJson(Map<String, dynamic> json) {
    return OtherMaterialStock(
      asOf: GodownJson.dateOf(json['as_of']),
      lines: JsonParser.asList(json['lines'], OtherMaterialStockLine.fromJson),
    );
  }

  @override
  List<Object?> get props => [asOf, lines];
}
