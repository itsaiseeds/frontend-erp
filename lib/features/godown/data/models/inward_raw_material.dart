import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'godown_refs.dart';
import 'inward_raw_status.dart';

/// One inward raw-material lot (`IR-…`).
///
/// Decimal quantities arrive as strings so no precision is lost on the way
/// through; they are kept that way and parsed only where a number is needed.
class InwardRawMaterial extends Equatable {
  final String publicId;
  final GodownProductRef product;
  final GodownPartyRef party;
  final GodownReturnOrderRef? returnOrder;
  final String farmerName;
  final String lotNo;
  final String quantityKg;
  final InwardRawStatus status;
  final DateTime? labSamplingDate;
  final DateTime? effectiveDate;
  final GodownActorRef? createdBy;

  const InwardRawMaterial({
    required this.publicId,
    this.product = const GodownProductRef(),
    this.party = const GodownPartyRef(),
    this.returnOrder,
    this.farmerName = '',
    this.lotNo = '',
    this.quantityKg = '',
    this.status = InwardRawStatus.unknown,
    this.labSamplingDate,
    this.effectiveDate,
    this.createdBy,
  });

  factory InwardRawMaterial.fromJson(Map<String, dynamic> json) {
    return InwardRawMaterial(
      publicId: JsonParser.asString(json['public_id']),
      product:
          GodownJson.refOf(json['product'], GodownProductRef.fromJson) ??
          const GodownProductRef(),
      party:
          GodownJson.refOf(json['party'], GodownPartyRef.fromJson) ??
          const GodownPartyRef(),
      returnOrder: GodownJson.refOf(
        json['return_order'],
        GodownReturnOrderRef.fromJson,
      ),
      farmerName: JsonParser.asString(json['farmer_name']),
      lotNo: JsonParser.asString(json['lot_no']),
      quantityKg: JsonParser.asString(json['quantity_kg']),
      status: InwardRawStatusX.fromRaw(JsonParser.asString(json['status'])),
      labSamplingDate: GodownJson.dateOf(json['lab_sampling_date']),
      effectiveDate: GodownJson.dateOf(json['effective_date']),
      createdBy: GodownJson.refOf(json['created_by'], GodownActorRef.fromJson),
    );
  }

  /// A lot an accepted return booked is owned by that return, so the godown
  /// never edits or deletes it here.
  bool get isReturnLot => returnOrder != null;

  List<InwardRawStatus> get allowedNextStatuses =>
      isReturnLot ? const [] : InwardRawStatusX.allowedNextFrom(status);

  bool get canChangeStatus => allowedNextStatuses.isNotEmpty;

  bool get canDelete => !isReturnLot;

  num? get quantityValue => num.tryParse(quantityKg.trim());

  @override
  List<Object?> get props => [
    publicId,
    product,
    party,
    returnOrder,
    farmerName,
    lotNo,
    quantityKg,
    status,
    labSamplingDate,
    effectiveDate,
    createdBy,
  ];
}
