import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// The return lifecycle. The API sends the status code without its
/// ``RETURN_`` prefix stripped -- ``RETURN_PENDING``, ``RETURN_ACCEPTED``,
/// ``RETURN_REJECTED`` -- so the raw codes are what [fromRaw] reads.
enum ReturnOrderStatus { pending, accepted, rejected, unknown }

class ReturnOrderStatusX {
  ReturnOrderStatusX._();

  static ReturnOrderStatus fromRaw(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'RETURN_PENDING':
      case 'PENDING':
        return ReturnOrderStatus.pending;
      case 'RETURN_ACCEPTED':
      case 'ACCEPTED':
        return ReturnOrderStatus.accepted;
      case 'RETURN_REJECTED':
      case 'REJECTED':
        return ReturnOrderStatus.rejected;
      default:
        return ReturnOrderStatus.unknown;
    }
  }

  static String labelOf(ReturnOrderStatus status) {
    switch (status) {
      case ReturnOrderStatus.pending:
        return 'Pending';
      case ReturnOrderStatus.accepted:
        return 'Accepted';
      case ReturnOrderStatus.rejected:
        return 'Rejected';
      case ReturnOrderStatus.unknown:
        return 'Unknown';
    }
  }

  static String rawOf(ReturnOrderStatus status) {
    switch (status) {
      case ReturnOrderStatus.pending:
        return 'RETURN_PENDING';
      case ReturnOrderStatus.accepted:
        return 'RETURN_ACCEPTED';
      case ReturnOrderStatus.rejected:
        return 'RETURN_REJECTED';
      case ReturnOrderStatus.unknown:
        return '';
    }
  }

  /// A pending return is the only state the sales person can still change by
  /// raising another, and the only one the admin has not settled yet.
  static bool isLive(ReturnOrderStatus status) =>
      status == ReturnOrderStatus.pending || status == ReturnOrderStatus.accepted;
}

/// The sales person or sales admin behind an action on the return. Null until
/// that action happens.
class ReturnUserRef extends Equatable {
  final int id;
  final String name;

  const ReturnUserRef({this.id = 0, this.name = ''});

  factory ReturnUserRef.fromJson(Map<String, dynamic> json) {
    return ReturnUserRef(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class ReturnOrderRef extends Equatable {
  final String publicId;
  final String status;

  const ReturnOrderRef({this.publicId = '', this.status = ''});

  factory ReturnOrderRef.fromJson(Map<String, dynamic> json) {
    return ReturnOrderRef(
      publicId: JsonParser.asString(json['public_id']),
      status: JsonParser.asString(json['status']),
    );
  }

  @override
  List<Object?> get props => [publicId, status];
}

class ReturnClientRef extends Equatable {
  final String publicId;
  final String companyName;

  const ReturnClientRef({this.publicId = '', this.companyName = ''});

  factory ReturnClientRef.fromJson(Map<String, dynamic> json) {
    return ReturnClientRef(
      publicId: JsonParser.asString(json['public_id']),
      companyName: JsonParser.asString(json['company_name']),
    );
  }

  @override
  List<Object?> get props => [publicId, companyName];
}

class ReturnProductRef extends Equatable {
  final String publicId;
  final String name;

  const ReturnProductRef({this.publicId = '', this.name = ''});

  factory ReturnProductRef.fromJson(Map<String, dynamic> json) {
    return ReturnProductRef(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [publicId, name];
}

/// One returned line: a product's packets of a single weight, and their price.
/// The unique key the API enforces is this product plus its packet weight, not
/// the product on its own.
class ReturnOrderItem extends Equatable {
  final ReturnProductRef product;
  final num packetWeight;
  final int packets;
  final num kg;
  final num pricePerPacket;
  final num lineTotal;

  const ReturnOrderItem({
    required this.product,
    this.packetWeight = 0,
    this.packets = 0,
    this.kg = 0,
    this.pricePerPacket = 0,
    this.lineTotal = 0,
  });

  factory ReturnOrderItem.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];
    final Map<String, dynamic> productMap = product is Map
        ? Map<String, dynamic>.from(product)
        : const {};

    return ReturnOrderItem(
      product: ReturnProductRef(
        publicId: JsonParser.asString(productMap['public_id']),
        name: JsonParser.asString(productMap['name']),
      ),
      // Every weight and money field arrives as a decimal string.
      packetWeight: JsonParser.asNum(json['packet_weight']),
      packets: JsonParser.asInt(json['packets']),
      kg: JsonParser.asNum(json['kg']),
      pricePerPacket: JsonParser.asNum(json['price_per_packet']),
      lineTotal: JsonParser.asNum(json['line_total']),
    );
  }

  String get packetSummary => '$packets x ${trimWeight(packetWeight)} kg';

  /// "5" rather than "5.000", but never "5.5" -> "5.50" -- the weight is a
  /// catalogue number the salesperson reads, not a computed figure.
  static String trimWeight(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    final String text = value.toString();
    return text.contains('.')
        ? text.substring(0, text.indexOf('.') + 2)
        : text;
  }

  @override
  List<Object?> get props => [
    product,
    packetWeight,
    packets,
    kg,
    pricePerPacket,
    lineTotal,
  ];
}

/// One return. A list row and a created/accepted return share a shape, so the
/// accept-only fields stay nullable rather than forcing a second model.
class ReturnOrder extends Equatable {
  final String publicId;
  final DateTime? createdAt;
  final DateTime? returnDate;
  final ReturnOrderStatus status;
  final ReturnOrderRef order;
  final ReturnClientRef client;
  final ReturnUserRef? createdBy;
  final ReturnUserRef? verifiedBy;
  final ReturnUserRef? rejectedBy;
  final List<ReturnOrderItem> items;
  final num totalKg;
  final num totalAmount;

  /// Set on accept: whether the packing material was booked too. Null while the
  /// return has not been accepted.
  final bool? includeInOtherRawMaterials;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final List<String> inwardRawMaterials;
  final List<String> inwardOtherMaterials;

  const ReturnOrder({
    required this.publicId,
    this.createdAt,
    this.returnDate,
    this.status = ReturnOrderStatus.unknown,
    this.order = const ReturnOrderRef(),
    this.client = const ReturnClientRef(),
    this.createdBy,
    this.verifiedBy,
    this.rejectedBy,
    this.items = const [],
    this.totalKg = 0,
    this.totalAmount = 0,
    this.includeInOtherRawMaterials,
    this.verifiedAt,
    this.rejectedAt,
    this.inwardRawMaterials = const [],
    this.inwardOtherMaterials = const [],
  });

  factory ReturnOrder.fromJson(Map<String, dynamic> json) {
    return ReturnOrder(
      publicId: JsonParser.asString(json['public_id']),
      createdAt: _parseInstant(json['created_at']),
      returnDate: _parseDateOnly(json['return_date']),
      status: ReturnOrderStatusX.fromRaw(JsonParser.asString(json['status'])),
      order: json['order'] is Map
          ? ReturnOrderRef.fromJson(
              Map<String, dynamic>.from(json['order'] as Map),
            )
          : const ReturnOrderRef(),
      client: json['client'] is Map
          ? ReturnClientRef.fromJson(
              Map<String, dynamic>.from(json['client'] as Map),
            )
          : const ReturnClientRef(),
      createdBy: _parseUser(json['created_by']),
      verifiedBy: _parseUser(json['verified_by']),
      rejectedBy: _parseUser(json['rejected_by']),
      items: JsonParser.asList(json['items'], ReturnOrderItem.fromJson),
      totalKg: JsonParser.asNum(json['total_kg']),
      totalAmount: JsonParser.asNum(json['total_amount']),
      includeInOtherRawMaterials: json['include_in_other_raw_materials'] == null
          ? null
          : JsonParser.asBool(json['include_in_other_raw_materials']),
      verifiedAt: _parseInstant(json['verified_at']),
      rejectedAt: _parseInstant(json['rejected_at']),
      inwardRawMaterials: _parseIds(json['inward_raw_materials']),
      inwardOtherMaterials: _parseIds(json['inward_other_materials']),
    );
  }

  /// An instant keeps UTC for the formatter to shift into IST. A date-only
  /// field carries no instant, so it is pinned to UTC midnight -- shifting it
  /// by a zone offset would roll it onto the wrong day off-IST.
  static DateTime? _parseInstant(dynamic value) {
    final String raw = JsonParser.asString(value).trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  static DateTime? _parseDateOnly(dynamic value) {
    final String raw = JsonParser.asString(value).trim();
    if (raw.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  static ReturnUserRef? _parseUser(dynamic value) {
    if (value is! Map) return null;
    return ReturnUserRef.fromJson(Map<String, dynamic>.from(value));
  }

  static List<String> _parseIds(dynamic value) {
    if (value is! List) return const [];
    return value.map((entry) => JsonParser.asString(entry)).toList();
  }

  int get totalPackets => items.fold(0, (total, line) => total + line.packets);

  bool get isLive => ReturnOrderStatusX.isLive(status);

  bool get canAccept => status == ReturnOrderStatus.pending;

  bool get canReject => status == ReturnOrderStatus.pending;

  bool get canRevertAccept => status == ReturnOrderStatus.accepted;

  bool get canUnreject => status == ReturnOrderStatus.rejected;

  /// A pending return can still be corrected; an accepted one has booked stock
  /// against it, and a rejected one is settled history.
  bool get canEdit => status == ReturnOrderStatus.pending;

  /// What the list search matches on. The endpoint has no free-text param, so
  /// this is what the loaded rows are matched against locally.
  bool matches(String term) {
    final String needle = term.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (publicId.toLowerCase().contains(needle)) return true;
    if (order.publicId.toLowerCase().contains(needle)) return true;
    if (client.companyName.toLowerCase().contains(needle)) return true;
    return items.any(
      (line) =>
          line.product.name.toLowerCase().contains(needle) ||
          line.product.publicId.toLowerCase().contains(needle),
    );
  }

  @override
  List<Object?> get props => [
    publicId,
    createdAt,
    returnDate,
    status,
    order,
    client,
    createdBy,
    verifiedBy,
    rejectedBy,
    items,
    totalKg,
    totalAmount,
    includeInOtherRawMaterials,
    verifiedAt,
    rejectedAt,
    inwardRawMaterials,
    inwardOtherMaterials,
  ];
}
