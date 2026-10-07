import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import '../../../godown/data/models/godown_refs.dart';
import '../../../godown/data/models/inward_raw_material.dart';

/// One completed (or awaiting re-test) lab test record (`LT-…`).
class LabTesting extends Equatable {
  final String publicId;
  final int numberOfPlants;
  final int femaleCount;
  final int otCount;
  final String geneticalImpurity;
  final String growOutTest;
  final String? result;
  final String comment;
  final GodownActorRef? testedBy;
  final DateTime? testedAt;
  final InwardRawMaterial inwardRawMaterial;

  const LabTesting({
    required this.publicId,
    this.numberOfPlants = 0,
    this.femaleCount = 0,
    this.otCount = 0,
    this.geneticalImpurity = '',
    this.growOutTest = '',
    this.result,
    this.comment = '',
    this.testedBy,
    this.testedAt,
    this.inwardRawMaterial = const InwardRawMaterial(publicId: ''),
  });

  factory LabTesting.fromJson(Map<String, dynamic> json) {
    final dynamic lot = json['inward_raw_material'];

    return LabTesting(
      publicId: JsonParser.asString(json['public_id']),
      numberOfPlants: JsonParser.asInt(json['number_of_plants']),
      femaleCount: JsonParser.asInt(json['female_count']),
      otCount: JsonParser.asInt(json['ot_count']),
      geneticalImpurity: JsonParser.asString(json['genetical_impurity']),
      growOutTest: JsonParser.asString(json['grow_out_test']),
      result: json['result'] as String?,
      comment: JsonParser.asString(json['comment']),
      testedBy: GodownJson.refOf(json['tested_by'], GodownActorRef.fromJson),
      testedAt: _dateTimeOf(json['tested_at']),
      inwardRawMaterial: lot is Map
          ? InwardRawMaterial.fromJson(Map<String, dynamic>.from(lot))
          : const InwardRawMaterial(publicId: ''),
    );
  }

  static DateTime? _dateTimeOf(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  bool get isPass => result == 'Pass';
  bool get isFail => result == 'Fail';

  @override
  List<Object?> get props => [
    publicId,
    numberOfPlants,
    femaleCount,
    otCount,
    geneticalImpurity,
    growOutTest,
    result,
    comment,
    testedBy,
    testedAt,
    inwardRawMaterial,
  ];
}
