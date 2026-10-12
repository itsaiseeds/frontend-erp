import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import '../../../godown/data/models/godown_refs.dart';

/// The date-bounded export payload from
/// `GET /android/api/v2/lab/export/lab-testings`.
///
/// The envelope is flatter than the paginated [GodownPage] the list screens
/// use -- a bare count plus results -- so it carries its own shape rather
/// than reusing that one. The nested lot block is flattened down to the few
/// values the report prints, and [status] is kept as the raw wire string so
/// a value this build does not recognise still prints instead of degrading
/// to a generic label.
class LabReportExport extends Equatable {
  final String startDate;
  final String endDate;
  final int count;
  final List<LabReportExportItem> results;

  const LabReportExport({
    this.startDate = '',
    this.endDate = '',
    this.count = 0,
    this.results = const [],
  });

  factory LabReportExport.fromJson(Map<String, dynamic> json) {
    final dynamic raw = json['results'];

    return LabReportExport(
      startDate: JsonParser.asString(json['start_date']),
      endDate: JsonParser.asString(json['end_date']),
      count: JsonParser.asInt(json['count']),
      results: raw is List
          ? raw
              .whereType<Map>()
              .map(
                (item) => LabReportExportItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [startDate, endDate, count, results];
}

/// One exported lab test, flattened to the values the PDF columns print.
class LabReportExportItem extends Equatable {
  final String publicId;
  final DateTime? testedAt;
  final String result;
  final int numberOfPlants;
  final int femaleCount;
  final int otCount;
  final String geneticalImpurity;
  final String growOutTest;
  final String testedByName;
  final String productName;
  final String lotNo;
  final String quantityKg;
  final String partyName;
  final String status;

  const LabReportExportItem({
    this.publicId = '',
    this.testedAt,
    this.result = '',
    this.numberOfPlants = 0,
    this.femaleCount = 0,
    this.otCount = 0,
    this.geneticalImpurity = '',
    this.growOutTest = '',
    this.testedByName = '',
    this.productName = '',
    this.lotNo = '',
    this.quantityKg = '',
    this.partyName = '',
    this.status = '',
  });

  factory LabReportExportItem.fromJson(Map<String, dynamic> json) {
    final dynamic lot = json['inward_raw_material'];
    final Map<String, dynamic> lotMap = lot is Map
        ? Map<String, dynamic>.from(lot)
        : const <String, dynamic>{};

    return LabReportExportItem(
      publicId: JsonParser.asString(json['public_id']),
      testedAt: GodownJson.dateOf(json['tested_at']),
      result: JsonParser.asString(json['result']),
      numberOfPlants: JsonParser.asInt(json['number_of_plants']),
      femaleCount: JsonParser.asInt(json['female_count']),
      otCount: JsonParser.asInt(json['ot_count']),
      geneticalImpurity: JsonParser.asString(json['genetical_impurity']),
      growOutTest: JsonParser.asString(json['grow_out_test']),
      testedByName:
          GodownJson.refOf(json['tested_by'], GodownActorRef.fromJson)?.name ??
          '',
      productName:
          GodownJson.refOf(
            lotMap['product'],
            GodownProductRef.fromJson,
          )?.name ??
          '',
      lotNo: JsonParser.asString(lotMap['lot_no']),
      quantityKg: JsonParser.asString(lotMap['quantity_kg']),
      partyName:
          GodownJson.refOf(lotMap['party'], GodownPartyRef.fromJson)?.name ??
          '',
      status: JsonParser.asString(lotMap['status']),
    );
  }

  bool get isPass => result == 'Pass';
  bool get isFail => result == 'Fail';

  @override
  List<Object?> get props => [
    publicId,
    testedAt,
    result,
    numberOfPlants,
    femaleCount,
    otCount,
    geneticalImpurity,
    growOutTest,
    testedByName,
    productName,
    lotNo,
    quantityKg,
    partyName,
    status,
  ];
}
