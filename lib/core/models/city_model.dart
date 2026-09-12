import '../utils/json_parser.dart';

class CityModel {
  final int id;
  final String name;
  final String stateName;
  final int stateId;

  const CityModel({
    required this.id,
    required this.name,
    this.stateName = '',
    this.stateId = 0,
  });

  factory CityModel.fromJson(
    Map<String, dynamic> json, {
    String stateName = '',
    int stateId = 0,
  }) {
    return CityModel(
      stateId: stateId,
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      stateName: stateName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CityModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
