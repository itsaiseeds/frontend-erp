import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'return_order.dart';

/// One challan line: what was dispatched for a product at a packet weight, what
/// is still returnable after any live return, and the price the API suggests
/// per packet (the order line's bag price divided by the packets in the bag).
class ReturnOrderPrefillLine extends Equatable {
  final ReturnProductRef product;
  final num packetWeight;
  final int dispatchedPackets;
  final int returnablePackets;
  final num suggestedPricePerPacket;

  const ReturnOrderPrefillLine({
    required this.product,
    this.packetWeight = 0,
    this.dispatchedPackets = 0,
    this.returnablePackets = 0,
    this.suggestedPricePerPacket = 0,
  });

  factory ReturnOrderPrefillLine.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];
    final Map<String, dynamic> productMap = product is Map
        ? Map<String, dynamic>.from(product)
        : const {};

    return ReturnOrderPrefillLine(
      product: ReturnProductRef(
        publicId: JsonParser.asString(productMap['public_id']),
        name: JsonParser.asString(productMap['name']),
      ),
      packetWeight: JsonParser.asNum(json['packet_weight']),
      dispatchedPackets: JsonParser.asInt(json['dispatched_packets']),
      returnablePackets: JsonParser.asInt(json['returnable_packets']),
      suggestedPricePerPacket: JsonParser.asNum(
        json['suggested_price_per_packet'],
      ),
    );
  }

  /// The API keys a return line on product plus weight, so that pair -- not the
  /// raw number -- is what identifies a line on both sides of the screen.
  String get weightKey => ReturnOrderItem.trimWeight(packetWeight);

  bool get isReturnable => returnablePackets > 0;

  @override
  List<Object?> get props => [
    product,
    packetWeight,
    dispatchedPackets,
    returnablePackets,
    suggestedPricePerPacket,
  ];
}

/// A product on the order with every packet weight it was dispatched in. The
/// picker lists products only -- packaging is a per-card choice, not something
/// the salesperson has to know about to find the product.
class ReturnOrderProduct extends Equatable {
  final String publicId;
  final String name;
  final List<ReturnOrderPrefillLine> lines;

  const ReturnOrderProduct({
    required this.publicId,
    required this.name,
    this.lines = const [],
  });

  /// Every weight this product was dispatched in, lightest first.
  List<ReturnOrderPrefillLine> get sortedLines {
    final List<ReturnOrderPrefillLine> sorted = [...lines];
    sorted.sort((a, b) => a.packetWeight.compareTo(b.packetWeight));
    return sorted;
  }

  ReturnOrderPrefillLine? lineForWeight(num weight) {
    final String wanted = ReturnOrderItem.trimWeight(weight);
    for (final ReturnOrderPrefillLine line in lines) {
      if (line.weightKey == wanted) return line;
    }
    return null;
  }

  int get totalReturnablePackets => lines.fold(
    0,
    (total, line) => total + line.returnablePackets,
  );

  @override
  List<Object?> get props => [publicId, name, lines];
}

/// The order summary on the prefill. Carries the client too -- the return
/// screen heads the form with who the goods are coming back from, and there is
/// no other call to make for it.
class ReturnOrderPrefillOrder extends Equatable {
  final String publicId;
  final String status;
  final ReturnClientRef client;

  const ReturnOrderPrefillOrder({
    this.publicId = '',
    this.status = '',
    this.client = const ReturnClientRef(),
  });

  factory ReturnOrderPrefillOrder.fromJson(Map<String, dynamic> json) {
    final dynamic client = json['client'];

    return ReturnOrderPrefillOrder(
      publicId: JsonParser.asString(json['public_id']),
      status: JsonParser.asString(json['status']),
      client: client is Map
          ? ReturnClientRef.fromJson(Map<String, dynamic>.from(client))
          : const ReturnClientRef(),
    );
  }

  @override
  List<Object?> get props => [publicId, status, client];
}

/// What the return screen opens with: the order being returned against, its
/// live return if one already exists, and the challan lines to pick from.
class ReturnOrderPrefill extends Equatable {
  final ReturnOrderPrefillOrder order;
  final ReturnOrder? returnOrder;
  final List<ReturnOrderPrefillLine> lines;

  const ReturnOrderPrefill({
    this.order = const ReturnOrderPrefillOrder(),
    this.returnOrder,
    this.lines = const [],
  });

  factory ReturnOrderPrefill.fromJson(Map<String, dynamic> json) {
    final dynamic returnOrder = json['return_order'];

    return ReturnOrderPrefill(
      order: json['order'] is Map
          ? ReturnOrderPrefillOrder.fromJson(
              Map<String, dynamic>.from(json['order'] as Map),
            )
          : const ReturnOrderPrefillOrder(),
      returnOrder: returnOrder is Map
          ? ReturnOrder.fromJson(Map<String, dynamic>.from(returnOrder))
          : null,
      lines: JsonParser.asList(json['lines'], ReturnOrderPrefillLine.fromJson),
    );
  }

  /// The products behind [lines], one entry per product with all of its
  /// weights, ordered by name -- the same order the API sends them in.
  List<ReturnOrderProduct> get products {
    final Map<String, ReturnOrderProduct> byId = {};

    for (final ReturnOrderPrefillLine line in lines) {
      final String id = line.product.publicId;
      if (id.isEmpty) continue;

      final ReturnOrderProduct? existing = byId[id];
      if (existing == null) {
        byId[id] = ReturnOrderProduct(
          publicId: id,
          name: line.product.name,
          lines: [line],
        );
      } else {
        byId[id] = ReturnOrderProduct(
          publicId: existing.publicId,
          name: existing.name,
          lines: [...existing.lines, line],
        );
      }
    }

    final List<ReturnOrderProduct> grouped = byId.values.toList();
    grouped.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return grouped;
  }

  /// Whether the order may still take a return. Only a dispatched or delivered
  /// order can, and only one live return at a time -- the same rules the API
  /// enforces, checked here so the screen can explain rather than 400.
  bool get isReturnableOrder =>
      ReturnOrderPrefillX.isReturnableOrderStatus(order.status);

  bool get hasLiveReturn => returnOrder?.isLive ?? false;

  bool get canCreate => isReturnableOrder && !hasLiveReturn && lines.isNotEmpty;

  /// The seed the edit form starts from: the live return's own lines, so an
  /// admin editing a pending return sees what is actually saved.
  List<ReturnOrderItem> get existingItems => returnOrder?.items ?? const [];

  @override
  List<Object?> get props => [order, returnOrder, lines];
}

class ReturnOrderPrefillX {
  ReturnOrderPrefillX._();

  /// Mirrors the backend's ``RETURNABLE_ORDER_STATUS_IDS``.
  static bool isReturnableOrderStatus(String status) {
    final String code = status.trim().toUpperCase();
    return code == 'DISPATCHED' || code == 'DELIVERED';
  }
}
