import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// Wire values of `Party.party_type`, shared by the two booking pickers so
/// a raw-material lot only offers raw suppliers and an other-material lot
/// only other-material ones. Mirrors the admin app's `PartyType`.
class GodownPartyType {
  GodownPartyType._();

  static const String rawMaterial = 'RAW_MATERIAL';
  static const String otherMaterial = 'OTHER_MATERIAL';
}

/// A product as the booking pickers need it. A product that is not usable
/// (the admin's `is_usable` flag) is filtered out by the repository before
/// this is ever built -- booking against one would be refused server-side.
class GodownPickableProduct extends Equatable {
  final String publicId;
  final String name;
  final bool isUsable;

  const GodownPickableProduct({
    this.publicId = '',
    this.name = '',
    this.isUsable = true,
  });

  factory GodownPickableProduct.fromJson(Map<String, dynamic> json) {
    return GodownPickableProduct(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
      isUsable: JsonParser.asBool(json['is_usable']),
    );
  }

  @override
  List<Object?> get props => [publicId, name, isUsable];
}

/// A party as the booking pickers need it: the id is what the API wants,
/// the name (plus city, for the rare same-name case) is what a person reads.
class GodownPickableParty extends Equatable {
  final int id;
  final String name;
  final String cityName;
  final String partyType;

  const GodownPickableParty({
    this.id = 0,
    this.name = '',
    this.cityName = '',
    this.partyType = '',
  });

  factory GodownPickableParty.fromJson(Map<String, dynamic> json) {
    final dynamic city = json['city'];
    return GodownPickableParty(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      cityName: city is Map ? JsonParser.asString(city['name']) : '',
      partyType: JsonParser.asString(json['party_type']),
    );
  }

  String get label => cityName.trim().isEmpty ? name : '$name ($cityName)';

  @override
  List<Object?> get props => [id, name, cityName, partyType];
}
