import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/json_parser.dart';

class ProductPackaging extends Equatable {
  final String publicId;
  final String name;
  final String productPublicId;
  final String productName;
  final String stageName;
  final int stageSequence;
  final String imageUrl;
  final List<String> descriptionItems;
  final num packetWeight;
  final int packets;
  final num totalWeight;
  final num sellingPrice;

  const ProductPackaging({
    required this.publicId,
    this.name = '',
    this.productPublicId = '',
    this.productName = '',
    this.stageName = '',
    this.stageSequence = 0,
    this.imageUrl = '',
    this.descriptionItems = const [],
    this.packetWeight = 0,
    this.packets = 0,
    this.totalWeight = 0,
    this.sellingPrice = 0,
  });

  factory ProductPackaging.fromJson(Map<String, dynamic> json) {
    final dynamic product = json['product'];
    final Map<String, dynamic> productMap = product is Map
        ? Map<String, dynamic>.from(product)
        : const {};

    final dynamic stage = productMap['stage'];
    final Map<String, dynamic> stageMap = stage is Map
        ? Map<String, dynamic>.from(stage)
        : const {};

    return ProductPackaging(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
      productPublicId: JsonParser.asString(productMap['public_id']),
      productName: JsonParser.asString(productMap['name']),
      stageName: JsonParser.asString(stageMap['name']),
      stageSequence: JsonParser.asInt(stageMap['sequence']),
      imageUrl: JsonParser.asString(productMap['image_url']),
      descriptionItems: _itemsOf(productMap['description_items']),
      packetWeight: JsonParser.asNum(json['packet_weight']),
      packets: JsonParser.asInt(json['packets']),
      totalWeight: JsonParser.asNum(json['total_weight']),
      sellingPrice: JsonParser.asNum(json['selling_price']),
    );
  }

  /// "40 packets x 1 kg" - the make-up of one bag.
  String get packetSummary {
    final List<String> parts = [];
    if (packets > 0) parts.add('$packets ${AppStrings.PACKETS_LABEL}');
    if (packetWeight > 0) {
      parts.add('${_trim(packetWeight)} ${AppStrings.KG_LABEL}');
    }
    return parts.join(' × ');
  }

  /// "60 Kg" - the bag weight, shown as a tag over the product shot.
  String get totalWeightSummary {
    if (totalWeight <= 0) return '';
    return '${_trim(totalWeight)} ${AppStrings.KG_UNIT}';
  }

  String get bagSummary {
    final String head = packetSummary;
    final String total = totalWeightSummary;
    if (head.isEmpty) return total;
    if (total.isEmpty) return head;
    return '$head • $total';
  }

  static String _trim(num value) {
    return value == value.roundToDouble() ? value.toInt().toString() : '$value';
  }

  static List<String> _itemsOf(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [
    publicId,
    name,
    productPublicId,
    productName,
    stageName,
    stageSequence,
    imageUrl,
    descriptionItems,
    packetWeight,
    packets,
    totalWeight,
    sellingPrice,
  ];
}
