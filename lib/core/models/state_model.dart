import '../utils/json_parser.dart';
import 'city_model.dart';

class StateModel {
  final int id;
  final String name;
  final String code;
  final int countryId;
  final List<CityModel> cities;

  const StateModel({
    required this.id,
    required this.name,
    this.code = '',
    this.countryId = 0,
    this.cities = const [],
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    final String stateName = JsonParser.asString(json['name']);
    final int stateId = JsonParser.asInt(json['id']);
    final dynamic rawCities = json['cities'];

    return StateModel(
      id: stateId,
      name: stateName,
      code: JsonParser.asString(json['code']),
      countryId: JsonParser.asInt(json['country_id']),
      cities: rawCities is List
          ? rawCities
                .whereType<Map>()
                .map(
                  (city) => CityModel.fromJson(
                    Map<String, dynamic>.from(city),
                    stateName: stateName,
                    stateId: stateId,
                  ),
                )
                .toList()
          : const [],
    );
  }
}
