import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// One packaging's live bag position from `godown/bag-stock`: on hand,
/// reserved, consumed and still-sellable, derived server-side from order
/// status rather than stored -- never present until that packaging has been
/// counted at least once.
class BagStockPosition extends Equatable {
  final String packagingPublicId;
  final int onHand;
  final int reserved;
  final int consumed;
  final int available;

  const BagStockPosition({
    this.packagingPublicId = '',
    this.onHand = 0,
    this.reserved = 0,
    this.consumed = 0,
    this.available = 0,
  });

  factory BagStockPosition.fromJson(Map<String, dynamic> json) {
    final dynamic packaging = json['packaging'];
    return BagStockPosition(
      packagingPublicId: packaging is Map
          ? JsonParser.asString(packaging['public_id'])
          : '',
      onHand: JsonParser.asInt(json['on_hand']),
      reserved: JsonParser.asInt(json['reserved']),
      consumed: JsonParser.asInt(json['consumed']),
      available: JsonParser.asInt(json['available']),
    );
  }

  @override
  List<Object?> get props => [
    packagingPublicId,
    onHand,
    reserved,
    consumed,
    available,
  ];
}

/// One `(product, packet_weight)` pool's live loose position from
/// `godown/sample-packet-stock`. Same figures as [BagStockPosition], keyed by
/// the pair instead of a packaging -- the loose write endpoint's real
/// identity.
class PacketStockPosition extends Equatable {
  final String productPublicId;
  final String packetWeight;
  final int onHand;
  final int reserved;
  final int consumed;
  final int available;

  const PacketStockPosition({
    this.productPublicId = '',
    this.packetWeight = '',
    this.onHand = 0,
    this.reserved = 0,
    this.consumed = 0,
    this.available = 0,
  });

  factory PacketStockPosition.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];
    return PacketStockPosition(
      productPublicId: product is Map
          ? JsonParser.asString(product['public_id'])
          : '',
      packetWeight: JsonParser.asString(json['packet_weight']),
      onHand: JsonParser.asInt(json['on_hand']),
      reserved: JsonParser.asInt(json['reserved']),
      consumed: JsonParser.asInt(json['consumed']),
      available: JsonParser.asInt(json['available']),
    );
  }

  /// Matches `PacketStockDraftLine.draftKey` so a position looks up against
  /// the same `(product, packet_weight)` identity the draft map uses.
  String get draftKey => '$productPublicId|$packetWeight';

  @override
  List<Object?> get props => [
    productPublicId,
    packetWeight,
    onHand,
    reserved,
    consumed,
    available,
  ];
}
