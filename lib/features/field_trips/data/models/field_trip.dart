import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'field_trip_status.dart';

class FieldTripCity extends Equatable {
  final int id;
  final String name;

  const FieldTripCity({this.id = 0, this.name = ''});

  factory FieldTripCity.fromJson(Map<String, dynamic> json) {
    return FieldTripCity(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class FieldTripPerson extends Equatable {
  final int id;
  final String name;
  final String phoneNumber;

  const FieldTripPerson({this.id = 0, this.name = '', this.phoneNumber = ''});

  factory FieldTripPerson.fromJson(Map<String, dynamic> json) {
    return FieldTripPerson(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      phoneNumber: JsonParser.asString(json['phone_number']),
    );
  }

  bool get isEmpty => name.trim().isEmpty && phoneNumber.trim().isEmpty;

  @override
  List<Object?> get props => [id, name, phoneNumber];
}

class FieldTrip extends Equatable {
  final String publicId;
  final FieldTripStatus status;
  final FieldTripCity city;
  final String village;
  final DateTime? expectedStartAt;
  final DateTime? expectedEndAt;

  /// Only stamped once the trip actually moves, so both stay null on a plan
  /// that has not been started.
  final DateTime? startedAt;
  final DateTime? endedAt;
  final FieldTripPerson salesPerson;

  /// A salesperson cannot approve their own trip, so this stays null until a
  /// sales admin acts on it.
  final FieldTripPerson? approvedBy;
  final DateTime? approvedAt;
  final int farmerVisitCount;
  final DateTime? createdAt;

  const FieldTrip({
    required this.publicId,
    this.status = FieldTripStatus.unknown,
    this.city = const FieldTripCity(),
    this.village = '',
    this.expectedStartAt,
    this.expectedEndAt,
    this.startedAt,
    this.endedAt,
    this.salesPerson = const FieldTripPerson(),
    this.approvedBy,
    this.approvedAt,
    this.farmerVisitCount = 0,
    this.createdAt,
  });

  factory FieldTrip.fromJson(Map<String, dynamic> json) {
    final dynamic approver = json['approved_by'];
    final FieldTripPerson? parsedApprover = approver is Map
        ? FieldTripPerson.fromJson(Map<String, dynamic>.from(approver))
        : null;

    return FieldTrip(
      publicId: JsonParser.asString(json['public_id']),
      status: FieldTripStatusX.fromRaw(JsonParser.asString(json['status'])),
      city: json['city'] is Map
          ? FieldTripCity.fromJson(Map<String, dynamic>.from(json['city'] as Map))
          : const FieldTripCity(),
      village: JsonParser.asString(json['village']),
      expectedStartAt: parseInstant(json['expected_start_at']),
      expectedEndAt: parseInstant(json['expected_end_at']),
      startedAt: parseInstant(json['started_at']),
      endedAt: parseInstant(json['ended_at']),
      salesPerson: json['sales_person'] is Map
          ? FieldTripPerson.fromJson(
              Map<String, dynamic>.from(json['sales_person'] as Map),
            )
          : const FieldTripPerson(),
      approvedBy: parsedApprover != null && !parsedApprover.isEmpty
          ? parsedApprover
          : null,
      approvedAt: parseInstant(json['approved_at']),
      farmerVisitCount: JsonParser.asInt(json['farmer_visit_count']),
      createdAt: parseInstant(json['created_at']),
    );
  }

  /// Every stamp on a trip is an instant, kept in UTC for the formatter to
  /// shift into IST rather than being read in the device zone.
  static DateTime? parseInstant(dynamic value) {
    final String raw = JsonParser.asString(value).trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  bool get canEdit => FieldTripStatusX.canEdit(status);

  bool get canDelete => FieldTripStatusX.canDelete(status);

  bool get canStart => FieldTripStatusX.canStart(status);

  bool get canEnd => FieldTripStatusX.canEnd(status);

  bool get canRecordFarmer => FieldTripStatusX.canRecordFarmer(status);

  bool get isApproved => approvedBy != null || approvedAt != null;

  /// Nothing the salesperson does moves a planned trip along -- a sales
  /// admin has to approve it -- so the detail screen says so out loud.
  bool get isAwaitingApproval => status == FieldTripStatus.planned;

  /// "Surat - Kamrej" when both are known, otherwise whichever one is.
  String get destination {
    final String cityName = city.name.trim();
    final String villageName = village.trim();
    if (cityName.isEmpty) return villageName;
    if (villageName.isEmpty) return cityName;
    return '$cityName - $villageName';
  }

  @override
  List<Object?> get props => [
    publicId,
    status,
    city,
    village,
    expectedStartAt,
    expectedEndAt,
    startedAt,
    endedAt,
    salesPerson,
    approvedBy,
    approvedAt,
    farmerVisitCount,
    createdAt,
  ];
}
