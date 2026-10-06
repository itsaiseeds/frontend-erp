import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// The two shapes every godown payload repeats: a nested object that may be
/// null, and a plain `YYYY-MM-DD` calendar date that may be null.
class GodownJson {
  GodownJson._();

  static T? refOf<T>(dynamic value, T Function(Map<String, dynamic>) parser) =>
      value is Map ? parser(Map<String, dynamic>.from(value)) : null;

  static DateTime? dateOf(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }
}

/// A product as a lot or recipe references it: public id plus name, nothing
/// more. The full catalogue row lives in the products feature.
class GodownProductRef extends Equatable {
  final String publicId;
  final String name;

  const GodownProductRef({this.publicId = '', this.name = ''});

  factory GodownProductRef.fromJson(Map<String, dynamic> json) {
    return GodownProductRef(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [publicId, name];
}

/// The supplier a lot was booked against.
///
/// A lot an accepted return booked has no party: [id] is null and [name]
/// reads "Return Order (ORD-…)".
class GodownPartyRef extends Equatable {
  final int? id;
  final String name;

  const GodownPartyRef({this.id, this.name = ''});

  factory GodownPartyRef.fromJson(Map<String, dynamic> json) {
    return GodownPartyRef(
      id: JsonParser.asNullableInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// A material type. [unitType] is absent where a lot nests it, present on a
/// recipe and on the stock lines.
class GodownMaterialTypeRef extends Equatable {
  final int id;
  final String name;
  final String unitType;

  const GodownMaterialTypeRef({
    this.id = 0,
    this.name = '',
    this.unitType = '',
  });

  factory GodownMaterialTypeRef.fromJson(Map<String, dynamic> json) {
    return GodownMaterialTypeRef(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      unitType: JsonParser.asString(json['unit_type']),
    );
  }

  @override
  List<Object?> get props => [id, name, unitType];
}

/// The accepted return that booked a lot; null for an ordinary booking.
class GodownReturnOrderRef extends Equatable {
  final String publicId;
  final String orderPublicId;

  const GodownReturnOrderRef({this.publicId = '', this.orderPublicId = ''});

  factory GodownReturnOrderRef.fromJson(Map<String, dynamic> json) {
    return GodownReturnOrderRef(
      publicId: JsonParser.asString(json['public_id']),
      orderPublicId: JsonParser.asString(json['order_public_id']),
    );
  }

  @override
  List<Object?> get props => [publicId, orderPublicId];
}

/// Who booked the lot.
class GodownActorRef extends Equatable {
  final int id;
  final String name;

  const GodownActorRef({this.id = 0, this.name = ''});

  factory GodownActorRef.fromJson(Map<String, dynamic> json) {
    return GodownActorRef(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// A supplier from `utilities/parties`, for the booking pickers.
class PartyOption extends Equatable {
  final int id;
  final String name;
  final String cityName;
  final String contactNumber;

  const PartyOption({
    required this.id,
    this.name = '',
    this.cityName = '',
    this.contactNumber = '',
  });

  factory PartyOption.fromJson(Map<String, dynamic> json) {
    final dynamic city = json['city'];

    return PartyOption(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      cityName: city is Map
          ? JsonParser.asString(Map<String, dynamic>.from(city)['name'])
          : '',
      contactNumber: JsonParser.asString(json['contact_number']),
    );
  }

  String get label =>
      cityName.trim().isEmpty ? name : '$name - ${cityName.trim()}';

  @override
  List<Object?> get props => [id, name, cityName, contactNumber];
}

/// A product from `utilities/products`, for the raw-material booking picker.
///
/// A frozen product (`is_usable` false) is listed there but refused by every
/// stock and booking action, so the picker drops it.
class ProductOption extends Equatable {
  final String publicId;
  final String name;
  final String cropName;
  final bool isUsable;
  final bool isDeleted;

  const ProductOption({
    required this.publicId,
    this.name = '',
    this.cropName = '',
    this.isUsable = true,
    this.isDeleted = false,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
      cropName: JsonParser.asString(json['crop']),
      isUsable: JsonParser.asBool(json['is_usable']),
      isDeleted: JsonParser.asBool(json['is_deleted']),
    );
  }

  bool get isBookable => isUsable && !isDeleted;

  String get label =>
      cropName.trim().isEmpty ? name : '$name - ${cropName.trim()}';

  @override
  List<Object?> get props => [publicId, name, cropName, isUsable, isDeleted];
}
