import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'order_status.dart';

/// One ordered line: the **bag** that was bought, how many of it, and the
/// product it holds. Two sizes of the same seed are two lines, not one
/// product listed twice.
class OrderPackaging extends Equatable {
  final String publicId;
  final String productPublicId;
  final String productName;
  final String imageUrl;
  final num packetWeight;
  final int packets;
  final num totalWeight;

  /// The catalogue price of the bag. ``negotiatedSellingPrice`` is what this
  /// order actually charged, which is what the line total is built from.
  final num sellingPrice;
  final num negotiatedSellingPrice;
  final int quantity;

  const OrderPackaging({
    required this.publicId,
    this.productPublicId = '',
    this.productName = '',
    this.imageUrl = '',
    this.packetWeight = 0,
    this.packets = 0,
    this.totalWeight = 0,
    this.sellingPrice = 0,
    this.negotiatedSellingPrice = 0,
    this.quantity = 0,
  });

  factory OrderPackaging.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];
    final Map<String, dynamic> productMap = product is Map
        ? Map<String, dynamic>.from(product)
        : const {};

    return OrderPackaging(
      publicId: JsonParser.asString(json['public_id']),
      productPublicId: JsonParser.asString(productMap['public_id']),
      productName: JsonParser.asString(productMap['name']),
      imageUrl: JsonParser.asString(productMap['image_url']),
      // Every numeric field on this line is sent as a decimal string.
      packetWeight: JsonParser.asNum(json['packet_weight']),
      packets: JsonParser.asInt(json['packets']),
      totalWeight: JsonParser.asNum(json['total_weight']),
      sellingPrice: JsonParser.asNum(json['selling_price']),
      negotiatedSellingPrice: JsonParser.asNum(
        json['negotiated_selling_price'],
      ),
      quantity: JsonParser.asInt(json['quantity']),
    );
  }

  /// What this line cost: the agreed bag price times how many bags.
  num get lineTotal => negotiatedSellingPrice * quantity;

  /// True when the order was booked at something other than list price, which
  /// is worth surfacing rather than hiding.
  bool get isNegotiated =>
      sellingPrice > 0 && negotiatedSellingPrice != sellingPrice;

  String get packetSummary => '$packets x ${_trim(packetWeight)} kg';

  String get totalWeightSummary => '${_trim(totalWeight)} Kg';

  static String _trim(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  List<Object?> get props => [
    publicId,
    productPublicId,
    productName,
    imageUrl,
    packetWeight,
    packets,
    totalWeight,
    sellingPrice,
    negotiatedSellingPrice,
    quantity,
  ];
}

class OrderCity extends Equatable {
  final int id;
  final String name;

  const OrderCity({this.id = 0, this.name = ''});

  factory OrderCity.fromJson(Map<String, dynamic> json) {
    return OrderCity(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class OrderClient extends Equatable {
  final String publicId;
  final String companyName;

  const OrderClient({this.publicId = '', this.companyName = ''});

  factory OrderClient.fromJson(Map<String, dynamic> json) {
    return OrderClient(
      publicId: JsonParser.asString(json['public_id']),
      companyName: JsonParser.asString(json['company_name']),
    );
  }

  @override
  List<Object?> get props => [publicId, companyName];
}

class Order extends Equatable {
  /// ``dispatch_mode`` is derived server-side: an agency was chosen, or the
  /// client collects it themselves.
  static const String DISPATCH_AGENCY = 'AGENCY';

  final String publicId;
  final DateTime? createdAt;
  final OrderStatus status;
  final OrderClient client;
  final String deliveryAddress;
  final OrderCity? city;
  final DateTime? expectedDeliveryDate;
  final String dispatchMode;
  final num totalAmount;
  final int totalPackets;
  final int itemCount;
  final List<OrderPackaging> packagings;

  /// Sales-admin approval, separate from the lifecycle status.
  /// ``verifiedBy`` / ``verifiedAt`` stay empty until it happens.
  final bool isVerified;
  final String verifiedBy;
  final DateTime? verifiedAt;

  const Order({
    required this.publicId,
    this.createdAt,
    this.status = OrderStatus.unknown,
    this.client = const OrderClient(),
    this.deliveryAddress = '',
    this.city,
    this.expectedDeliveryDate,
    this.dispatchMode = '',
    this.totalAmount = 0,
    this.totalPackets = 0,
    this.itemCount = 0,
    this.packagings = const [],
    this.isVerified = false,
    this.verifiedBy = '',
    this.verifiedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final dynamic city = json['city'];

    return Order(
      publicId: JsonParser.asString(json['public_id']),
      createdAt: _parseInstant(json['created_at']),
      status: OrderStatusX.fromRaw(JsonParser.asString(json['status'])),
      client: json['client'] is Map
          ? OrderClient.fromJson(
              Map<String, dynamic>.from(json['client'] as Map),
            )
          : const OrderClient(),
      deliveryAddress: JsonParser.asString(json['delivery_address']),
      city: city is Map
          ? OrderCity.fromJson(Map<String, dynamic>.from(city))
          : null,
      expectedDeliveryDate: _parseDateOnly(json['expected_delivery_date']),
      dispatchMode: JsonParser.asString(json['dispatch_mode']),
      // Sent as a decimal string, not a number.
      totalAmount: JsonParser.asNum(json['total_amount']),
      totalPackets: JsonParser.asInt(json['total_packets']),
      itemCount: JsonParser.asInt(json['item_count']),
      packagings: JsonParser.asList(
        json['packagings'],
        OrderPackaging.fromJson,
      ),
      isVerified: JsonParser.asBool(json['verified']),
      verifiedBy: JsonParser.asString(json['verified_by']),
      verifiedAt: _parseInstant(json['verified_at']),
    );
  }

  /// An instant (``created_at``) keeps its UTC value for the formatter to
  /// shift into IST. A date-only field (``expected_delivery_date``) carries no
  /// instant, so it is pinned to UTC midnight -- shifting it by a zone offset
  /// would roll it onto the wrong day on a device outside IST.
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

  bool get isAgencyDispatch => dispatchMode.toUpperCase() == DISPATCH_AGENCY;

  String get cityName => city?.name ?? '';

  /// Bags ordered across every line.
  int get bagCount =>
      packagings.fold(0, (total, line) => total + line.quantity);

  @override
  List<Object?> get props => [
    publicId,
    createdAt,
    status,
    client,
    deliveryAddress,
    city,
    expectedDeliveryDate,
    dispatchMode,
    totalAmount,
    totalPackets,
    itemCount,
    packagings,
    isVerified,
    verifiedBy,
    verifiedAt,
  ];
}
