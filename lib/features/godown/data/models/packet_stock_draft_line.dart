import 'package:equatable/equatable.dart';

import 'product_packaging.dart';
import 'stock_position.dart';

/// One row the packet-stock screen shows: a `(product, packet_weight)` pair
/// --identity is the pair, not a packaging public_id, since the write
/// endpoint keys on it-- plus whatever count is currently in the draft for
/// it, plus its live position if it has ever been counted.
class PacketStockDraftLine extends Equatable {
  final GodownProductPackaging packaging;
  final int? draftCount;
  final PacketStockPosition? position;

  const PacketStockDraftLine({
    required this.packaging,
    this.draftCount,
    this.position,
  });

  String get productPublicId => packaging.product.publicId;

  String get packetWeight => packaging.packetWeight;

  bool get hasPosition => position != null;

  /// `(product, packet_weight)` composite key -- the write endpoint's real
  /// identity for this line, matching the admin's `poolKeyOf` convention.
  String get draftKey => draftKeyOf(productPublicId, packetWeight);

  static String draftKeyOf(String productPublicId, String packetWeight) =>
      '$productPublicId|$packetWeight';

  @override
  List<Object?> get props => [packaging, draftCount, position];
}
