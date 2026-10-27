import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// The address of a child org, in the same shape as [ClientAddress] minus its
/// link-only fields (no `id`, `label`, `is_primary`).
class ChildOrgAddress extends Equatable {
  final String line1;
  final String line2;
  final String pincode;
  final String cityName;
  final String stateName;
  final String countryName;
  final int cityId;
  final int stateId;
  final int countryId;
  final String deliveryTo;

  const ChildOrgAddress({
    this.line1 = '',
    this.line2 = '',
    this.pincode = '',
    this.cityName = '',
    this.stateName = '',
    this.countryName = '',
    this.cityId = 0,
    this.stateId = 0,
    this.countryId = 0,
    this.deliveryTo = '',
  });

  factory ChildOrgAddress.fromJson(Map<String, dynamic> json) {
    return ChildOrgAddress(
      line1: JsonParser.asString(json['line_1']),
      line2: JsonParser.asString(json['line_2']),
      pincode: JsonParser.asString(json['pincode']),
      cityName: JsonParser.asString(json['city']),
      stateName: JsonParser.asString(json['state']),
      countryName: JsonParser.asString(json['country']),
      cityId: JsonParser.asInt(json['city_id']),
      stateId: JsonParser.asInt(json['state_id']),
      countryId: JsonParser.asInt(json['country_id']),
      deliveryTo: JsonParser.asString(json['delivery_to']),
    );
  }

  String get formatted => [
    line1,
    line2,
    cityName,
    stateName,
    pincode,
  ].where((part) => part.trim().isNotEmpty).join(', ');

  @override
  List<Object?> get props => [
    line1,
    line2,
    pincode,
    cityName,
    stateName,
    countryName,
    cityId,
    stateId,
    countryId,
    deliveryTo,
  ];
}

/// A client's "delivery place" booked on their behalf -- called "Delivery To"
/// everywhere in the UI, never the backend's own "booked for"/"child org"
/// wording. An order list row carries only [id]/[partyName]/[villageName]
/// (the short shape); a single order or the picker list carries every field
/// (the full shape). Both parse through this one type, short fields simply
/// defaulting when the server omits them.
class ChildOrg extends Equatable {
  final int id;
  final String partyName;
  final String villageName;
  final String transportName;
  final String contactNumber;
  final ChildOrgAddress? address;

  const ChildOrg({
    required this.id,
    this.partyName = '',
    this.villageName = '',
    this.transportName = '',
    this.contactNumber = '',
    this.address,
  });

  factory ChildOrg.fromJson(Map<String, dynamic> json) {
    final dynamic address = json['address'];

    return ChildOrg(
      id: JsonParser.asInt(json['id']),
      partyName: JsonParser.asString(json['party_name']),
      villageName: JsonParser.asString(json['village_name']),
      transportName: JsonParser.asString(json['transport_name']),
      contactNumber: JsonParser.asString(json['contact_number']),
      address: address is Map
          ? ChildOrgAddress.fromJson(Map<String, dynamic>.from(address))
          : null,
    );
  }

  /// "PartyName, VillageName" -- how a delivery place reads everywhere: a
  /// picker option, an order card, an order's delivery details.
  String get label {
    final List<String> parts = [partyName, villageName]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    partyName,
    villageName,
    transportName,
    contactNumber,
    address,
  ];
}
