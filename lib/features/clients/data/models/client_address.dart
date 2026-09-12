import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

class ClientAddress extends Equatable {
  final String label;
  final String line1;
  final String line2;
  final String pincode;
  final String cityName;
  final String stateName;
  final String countryName;
  final int cityId;
  final int stateId;
  final int countryId;
  final bool isPrimary;

  const ClientAddress({
    required this.line1,
    this.label = '',
    this.line2 = '',
    this.pincode = '',
    this.cityName = '',
    this.stateName = '',
    this.countryName = '',
    this.cityId = 0,
    this.stateId = 0,
    this.countryId = 0,
    this.isPrimary = false,
  });

  factory ClientAddress.fromJson(Map<String, dynamic> json) {
    return ClientAddress(
      label: JsonParser.asString(json['label']),
      line1: JsonParser.asString(json['line_1']),
      line2: JsonParser.asString(json['line_2']),
      pincode: JsonParser.asString(json['pincode']),
      cityName: JsonParser.asString(json['city']),
      stateName: JsonParser.asString(json['state']),
      countryName: JsonParser.asString(json['country']),
      cityId: JsonParser.asInt(json['city_id']),
      stateId: JsonParser.asInt(json['state_id']),
      countryId: JsonParser.asInt(json['country_id']),
      isPrimary: JsonParser.asBool(json['is_primary']),
    );
  }

  Map<String, dynamic> toWriteJson() => {
    'line_1': line1,
    'line_2': line2,
    'pincode': pincode,
    'city': cityId,
    'state': stateId,
    'country': countryId,
    'label': label,
    'is_primary': isPrimary,
  };

  String get formatted => [
    line1,
    line2,
    cityName,
    stateName,
    pincode,
  ].where((part) => part.trim().isNotEmpty).join(', ');

  String get cityWithState {
    if (cityName.isEmpty) return stateName;
    if (stateName.isEmpty) return cityName;
    return '$cityName, $stateName';
  }

  @override
  List<Object?> get props => [
    label,
    line1,
    line2,
    pincode,
    cityName,
    stateName,
    countryName,
    cityId,
    stateId,
    countryId,
    isPrimary,
  ];
}
