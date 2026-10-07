import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';

/// One entry from `utilities/sales-persons` -- a sales person an admin may
/// book an order for. `id` is what the admin sends back as `created_by` when
/// placing the order and as `sales_person_id` on the client/address/agency
/// look-ups.
class SalesPersonOption extends Equatable {
  final int id;
  final String name;

  const SalesPersonOption({required this.id, this.name = ''});

  factory SalesPersonOption.fromJson(Map<String, dynamic> json) {
    return SalesPersonOption(
      id: JsonParser.asInt(json['id']),
      name: JsonParser.asString(json['name']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}
