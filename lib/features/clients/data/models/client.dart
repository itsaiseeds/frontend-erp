import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_parser.dart';
import 'client_address.dart';
import 'client_contact.dart';
import 'client_status.dart';
import 'transport_agency.dart';

class Client extends Equatable {
  final String publicId;
  final String companyName;
  final String companyPhone;
  final String gstNumber;
  final ClientStatus status;
  final bool isVerified;
  final String verifiedAt;
  final String verifiedBy;
  final String createdBy;
  final ClientAddress? primaryAddress;
  final ClientContact? primaryContact;
  final List<ClientAddress> addresses;
  final List<ClientContact> contacts;
  final List<TransportAgency> transportAgencies;

  const Client({
    required this.publicId,
    required this.companyName,
    this.companyPhone = '',
    this.gstNumber = '',
    this.status = ClientStatus.unknown,
    this.isVerified = false,
    this.verifiedAt = '',
    this.verifiedBy = '',
    this.createdBy = '',
    this.primaryAddress,
    this.primaryContact,
    this.addresses = const [],
    this.contacts = const [],
    this.transportAgencies = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    final List<ClientAddress> addresses = JsonParser.asList(
      json['addresses'],
      ClientAddress.fromJson,
    );
    final List<ClientContact> contacts = JsonParser.asList(
      json['contacts'],
      ClientContact.fromJson,
    );

    return Client(
      publicId: JsonParser.asString(json['public_id']),
      companyName: JsonParser.asString(json['company_name']),
      companyPhone: JsonParser.asString(json['company_phone']),
      gstNumber: JsonParser.asString(json['gst_number']),
      status: ClientStatusX.fromRaw(JsonParser.asString(json['status'])),
      isVerified: JsonParser.asBool(json['is_verified']),
      verifiedAt: JsonParser.asString(json['verified_at']),
      verifiedBy: JsonParser.asString(json['verified_by']),
      createdBy: JsonParser.asString(json['created_by']),
      primaryAddress: json['primary_address'] is Map
          ? ClientAddress.fromJson(
              Map<String, dynamic>.from(json['primary_address'] as Map),
            )
          : _firstPrimary(addresses, (a) => a.isPrimary),
      primaryContact: json['primary_contact'] is Map
          ? ClientContact.fromJson(
              Map<String, dynamic>.from(json['primary_contact'] as Map),
            )
          : _firstPrimary(contacts, (c) => c.isPrimary),
      addresses: addresses,
      contacts: contacts,
      transportAgencies: JsonParser.asList(
        json['transport_agencies'],
        TransportAgency.fromJson,
      ),
    );
  }

  static T? _firstPrimary<T>(List<T> items, bool Function(T) isPrimary) {
    if (items.isEmpty) return null;
    for (final item in items) {
      if (isPrimary(item)) return item;
    }
    return items.first;
  }

  Map<String, dynamic> toCreateJson() => {
    'company_name': companyName,
    'company_phone': companyPhone,
    'gst_number': gstNumber,
    'addresses': addresses.map((a) => a.toWriteJson()).toList(),
    'contacts': contacts.map((c) => c.toWriteJson()).toList(),
    'transport_agencies': transportAgencies
        .map((t) => t.toWriteJson())
        .toList(),
  };

  Map<String, dynamic> toUpdateJson() => {
    'public_id': publicId,
    'addresses': addresses.map((a) => a.toWriteJson()).toList(),
    'contacts': contacts.map((c) => c.toWriteJson()).toList(),
    'transport_agencies': transportAgencies
        .map((t) => t.toWriteJson())
        .toList(),
  };

  String get cityName => primaryAddress?.cityName ?? '';

  bool get hasGstNumber => gstNumber.trim().isNotEmpty;

  Client mergedWith(Client detail) => detail;

  @override
  List<Object?> get props => [
    publicId,
    companyName,
    companyPhone,
    gstNumber,
    status,
    isVerified,
    verifiedAt,
    verifiedBy,
    createdBy,
    primaryAddress,
    primaryContact,
    addresses,
    contacts,
    transportAgencies,
  ];
}
