import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/json_parser.dart';

class TransportAgency extends Equatable {
  /// Link id from the client payload; the order endpoint's
  /// ``client_transport_agency_id``. Zero for an agency not yet saved.
  final int id;
  final String name;
  final bool isPrimary;

  const TransportAgency({
    required this.name,
    this.id = 0,
    this.isPrimary = false,
  });

  factory TransportAgency.fromJson(Map<String, dynamic> json) {
    return TransportAgency(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
      isPrimary: JsonParser.asBool(json['is_primary']),
    );
  }

  Map<String, dynamic> toWriteJson() => {'name': name, 'is_primary': isPrimary};

  /// Booking without an agency: the client collects it themselves. A link id
  /// of zero is never a real row, so the order body sends null for this and
  /// the backend books a private dispatch.
  static const TransportAgency PRIVATE_DISPATCH = TransportAgency(
    name: AppStrings.CART_PRIVATE_DISPATCH,
  );

  bool get isPrivateDispatch => id == 0;

  @override
  List<Object?> get props => [id, name, isPrimary];
}
