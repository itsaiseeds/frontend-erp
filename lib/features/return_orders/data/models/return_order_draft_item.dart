import 'package:equatable/equatable.dart';

import 'return_order.dart';

/// One line as the salesperson is building it, before it is sent.
///
/// It carries [maxPackets] because the count has to be bounded by what that
/// exact product-and-weight pair still has returnable on the challan, and the
/// bound only exists in the prefill -- a returned line on its own cannot say
/// how many packets were dispatched.
class ReturnOrderDraftItem extends Equatable {
  final String productPublicId;
  final String productName;
  final num packetWeight;
  final int packets;
  final num pricePerPacket;
  final int maxPackets;
  final int dispatchedPackets;

  const ReturnOrderDraftItem({
    required this.productPublicId,
    required this.productName,
    this.packetWeight = 0,
    this.packets = 1,
    this.pricePerPacket = 0,
    this.maxPackets = 0,
    this.dispatchedPackets = 0,
  });

  String get weightKey => ReturnOrderItem.trimWeight(packetWeight);

  String get weightLabel => '$weightKey kg';

  num get lineTotal => pricePerPacket * packets;

  num get kg => packetWeight * packets;

  bool get canSubmit => packets >= 1 && packets <= maxPackets && pricePerPacket >= 0;

  ReturnOrderDraftItem copyWith({
    num? packetWeight,
    int? packets,
    num? pricePerPacket,
    int? maxPackets,
    int? dispatchedPackets,
  }) {
    return ReturnOrderDraftItem(
      productPublicId: productPublicId,
      productName: productName,
      packetWeight: packetWeight ?? this.packetWeight,
      packets: packets ?? this.packets,
      pricePerPacket: pricePerPacket ?? this.pricePerPacket,
      maxPackets: maxPackets ?? this.maxPackets,
      dispatchedPackets: dispatchedPackets ?? this.dispatchedPackets,
    );
  }

  /// The write body for one ``items[]`` row. Weights and prices go as strings:
  /// the API declares them decimal fields, and a string keeps trailing zeros
  /// out of floating point on the way there.
  Map<String, dynamic> toRequest() {
    return {
      'product_public_id': productPublicId,
      'packet_weight': weightKey,
      'packets': packets,
      'price_per_packet': pricePerPacket.toStringAsFixed(2),
    };
  }

  @override
  List<Object?> get props => [
    productPublicId,
    productName,
    packetWeight,
    packets,
    pricePerPacket,
    maxPackets,
    dispatchedPackets,
  ];
}
