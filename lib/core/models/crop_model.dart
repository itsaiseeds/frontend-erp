import '../utils/json_parser.dart';

class CropModel {
  final int id;
  final String name;

  const CropModel({required this.id, this.name = ''});

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CropModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
