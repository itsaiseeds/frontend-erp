import 'package:equatable/equatable.dart';

import '../../../../core/models/city_model.dart';
import '../../../../core/utils/json_parser.dart';
import 'field_trip.dart';

class FarmerCrop extends Equatable {
  final int id;
  final String name;

  const FarmerCrop({this.id = 0, this.name = ''});

  factory FarmerCrop.fromJson(Map<String, dynamic> json) {
    return FarmerCrop(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class FarmerProduct extends Equatable {
  final String publicId;
  final String name;

  const FarmerProduct({this.publicId = '', this.name = ''});

  factory FarmerProduct.fromJson(Map<String, dynamic> json) {
    return FarmerProduct(
      publicId: JsonParser.asString(json['public_id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [publicId, name];
}

class FarmerVisit extends Equatable {
  final String publicId;
  final String farmerName;
  final String contactNumber;
  final String village;
  final String district;

  /// Labelled "Taluka" in the UI; the key stays `city`/`city_id` on the wire.
  final CityModel? city;

  /// Sent as a decimal string, so it is parsed rather than cast.
  final num landAreaBigha;
  final List<FarmerCrop> crops;
  final bool usesOurProducts;
  final List<FarmerProduct> products;
  final DateTime? createdAt;

  /// Flags a sales lead. Settable whether or not the farmer came from a trip.
  final bool isLead;

  /// Set only when this farmer was recorded on a trip; empty for one added
  /// directly from the standalone Farmers screen.
  final String fieldTripPublicId;

  const FarmerVisit({
    required this.publicId,
    this.farmerName = '',
    this.contactNumber = '',
    this.village = '',
    this.district = '',
    this.city,
    this.landAreaBigha = 0,
    this.crops = const [],
    this.usesOurProducts = false,
    this.products = const [],
    this.createdAt,
    this.isLead = false,
    this.fieldTripPublicId = '',
  });

  factory FarmerVisit.fromJson(Map<String, dynamic> json) {
    final dynamic city = json['city'];

    return FarmerVisit(
      publicId: JsonParser.asString(json['public_id']),
      farmerName: JsonParser.asString(json['farmer_name']),
      contactNumber: JsonParser.asString(json['contact_number']),
      village: JsonParser.asString(json['village']),
      district: JsonParser.asString(json['district']),
      city: city is Map
          ? CityModel.fromJson(Map<String, dynamic>.from(city))
          : null,
      landAreaBigha: JsonParser.asNum(json['land_area_bigha']),
      crops: JsonParser.asList(json['crops'], FarmerCrop.fromJson),
      usesOurProducts: JsonParser.asBool(json['uses_our_products']),
      products: JsonParser.asList(json['products'], FarmerProduct.fromJson),
      createdAt: FieldTrip.parseInstant(json['created_at']),
      isLead: JsonParser.asBool(json['is_lead']),
      fieldTripPublicId: JsonParser.asString(json['field_trip_public_id']),
    );
  }

  /// "2.5" rather than "2.5000", and "2" rather than "2.0".
  String get landAreaLabel {
    if (landAreaBigha == landAreaBigha.roundToDouble()) {
      return landAreaBigha.toInt().toString();
    }
    return landAreaBigha
        .toStringAsFixed(_MAX_DECIMALS)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static const int _MAX_DECIMALS = 4;

  String get cityName => city?.name ?? '';

  int? get cityId => city?.id;

  String get initial {
    final String trimmed = farmerName.trim();
    return trimmed.isEmpty ? '' : trimmed[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
    publicId,
    farmerName,
    contactNumber,
    village,
    district,
    city,
    landAreaBigha,
    crops,
    usesOurProducts,
    products,
    createdAt,
    isLead,
    fieldTripPublicId,
  ];
}
