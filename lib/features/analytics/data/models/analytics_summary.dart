import '../../../orders/data/models/order_status.dart';

/// One status bucket: how many, and what to call it.
class StatusCount {
  final String key;
  final String label;
  final int count;

  const StatusCount({
    required this.key,
    required this.label,
    required this.count,
  });
}

/// Order counts for a window, split by status.
///
/// The API always sends every bucket zero-filled, so the order of the
/// buckets here is the order they are shown in -- the lifecycle, not
/// whatever order the map happened to arrive in.
class OrderBreakdown {
  static const List<String> statusOrder = [
    'BOOKED',
    'UNDER_REVIEW',
    'CONFIRMED',
    'DISPATCHED',
    'DELIVERED',
    'ON_HOLD',
    'REJECTED',
  ];

  final int total;
  final Map<String, int> byStatus;

  const OrderBreakdown({this.total = 0, this.byStatus = const {}});

  factory OrderBreakdown.fromJson(Map<String, dynamic> json) {
    return OrderBreakdown(
      total: _asInt(json['total']),
      byStatus: _countsOf(json['by_status']),
    );
  }

  /// Buckets in lifecycle order, each with a human label.
  List<StatusCount> get buckets => [
    for (final String key in statusOrder)
      StatusCount(
        key: key,
        label: OrderStatusX.labelOf(OrderStatusX.fromRaw(key)),
        count: byStatus[key] ?? 0,
      ),
  ];

  /// Only the buckets that actually have orders. A pie of seven zero
  /// slices says nothing; the empty state is handled by the caller.
  List<StatusCount> get presentBuckets =>
      buckets.where((bucket) => bucket.count > 0).toList();

  bool get isEmpty => total == 0;
}

/// Client counts for a window, split by verification status.
class ClientBreakdown {
  static const String pending = 'VERIFICATION_PENDING';
  static const String verified = 'VERIFIED';

  final int total;
  final Map<String, int> byStatus;

  const ClientBreakdown({this.total = 0, this.byStatus = const {}});

  factory ClientBreakdown.fromJson(Map<String, dynamic> json) {
    return ClientBreakdown(
      total: _asInt(json['total']),
      byStatus: _countsOf(json['by_status']),
    );
  }

  int get verifiedCount => byStatus[verified] ?? 0;

  int get pendingCount => byStatus[pending] ?? 0;

  bool get isEmpty => total == 0;
}

class AnalyticsProductRef {
  final String publicId;
  final String name;

  const AnalyticsProductRef({this.publicId = '', this.name = ''});

  factory AnalyticsProductRef.fromJson(Map<String, dynamic> json) {
    return AnalyticsProductRef(
      publicId: '${json['public_id'] ?? ''}',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Kilograms booked for one product in the window, split by order status.
///
/// The API sends weights as decimal strings and these heaviest first, with
/// products that moved nothing left out entirely.
class ProductWeight {
  final AnalyticsProductRef? product;
  final String totalKg;
  final Map<String, String> kgByStatus;

  const ProductWeight({
    this.product,
    this.totalKg = '',
    this.kgByStatus = const {},
  });

  factory ProductWeight.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];

    return ProductWeight(
      product: product is Map
          ? AnalyticsProductRef.fromJson(Map<String, dynamic>.from(product))
          : null,
      totalKg: '${json['total_kg'] ?? ''}',
      kgByStatus: _weightsOf(json['kg_by_status']),
    );
  }

  String get productName => product?.name ?? '';

  double get totalValue => double.tryParse(totalKg.trim()) ?? 0;

  double kgFor(String status) =>
      double.tryParse(kgByStatus[status]?.trim() ?? '') ?? 0;

  double get deliveredKg => kgFor('DELIVERED');

  /// The weight split into its statuses, in lifecycle order, with the
  /// statuses carrying nothing left out.
  ///
  /// Shares OrderBreakdown.statusOrder so a product's bar reads left to
  /// right in the same sequence as the donut's slices.
  List<WeightSegment> get segments => [
    for (final String key in OrderBreakdown.statusOrder)
      if (kgFor(key) > 0) WeightSegment(key: key, kg: kgFor(key)),
  ];

  /// Weight the status split does not account for.
  ///
  /// The buckets should sum to the total, but a rounding gap -- or a status
  /// this app does not know about -- would otherwise leave a bar looking
  /// shorter than the number printed beside it.
  double get unattributedKg {
    final double attributed = segments.fold<double>(0, (s, x) => s + x.kg);
    final double gap = totalValue - attributed;
    return gap > 0 ? gap : 0;
  }
}

/// One status's share of a product's weight.
class WeightSegment {
  final String key;
  final double kg;

  const WeightSegment({required this.key, required this.kg});
}

class AnalyticsSummary {
  final String startDateTime;
  final String endDateTime;
  final OrderBreakdown orders;
  final ClientBreakdown clients;
  final List<ProductWeight> products;

  const AnalyticsSummary({
    this.startDateTime = '',
    this.endDateTime = '',
    this.orders = const OrderBreakdown(),
    this.clients = const ClientBreakdown(),
    this.products = const [],
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final dynamic orders = json['orders'];
    final dynamic clients = json['clients'];
    final dynamic products = json['products'];

    return AnalyticsSummary(
      startDateTime: '${json['start_date_time'] ?? ''}',
      endDateTime: '${json['end_date_time'] ?? ''}',
      orders: orders is Map
          ? OrderBreakdown.fromJson(Map<String, dynamic>.from(orders))
          : const OrderBreakdown(),
      clients: clients is Map
          ? ClientBreakdown.fromJson(Map<String, dynamic>.from(clients))
          : const ClientBreakdown(),
      products: products is List
          ? products
                .whereType<Map>()
                .map(
                  (item) =>
                      ProductWeight.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  /// Nothing happened in the window at all, so the page shows one empty
  /// state rather than three.
  bool get isEmpty => orders.isEmpty && clients.isEmpty;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

Map<String, String> _weightsOf(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries) '${entry.key}': '${entry.value ?? ''}',
  };
}

Map<String, int> _countsOf(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries) '${entry.key}': _asInt(entry.value),
  };
}
