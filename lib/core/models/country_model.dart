import 'package:equatable/equatable.dart';

import '../utils/json_parser.dart';

class CountryModel extends Equatable {
  final int id;
  final String name;
  final String isoCode;

  const CountryModel({required this.id, required this.name, this.isoCode = ''});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      isoCode: JsonParser.asString(json['iso_code']),
    );
  }

  @override
  List<Object?> get props => [id, name, isoCode];
}
