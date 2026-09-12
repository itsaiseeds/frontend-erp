import 'package:equatable/equatable.dart';

import '../../../../core/models/city_model.dart';
import '../../../../core/models/country_model.dart';
import '../../../../core/models/state_model.dart';
import '../../data/models/client_address.dart';
import '../../data/models/client_contact.dart';
import '../../data/models/transport_agency.dart';

enum ClientFormStep { details, addresses, contacts, transport }

enum ClientFormStatus { editing, submitting, success, failure }

abstract class MainFlaggable {
  int get key;

  bool get isMain;

  MainFlaggable withMain(bool value);
}

class AddressDraft extends Equatable implements MainFlaggable {
  @override
  final int key;
  final String label;
  final String line1;
  final String line2;
  final CityModel? city;
  final StateModel? state;
  final CountryModel? country;
  final String pincode;
  @override
  final bool isMain;

  const AddressDraft({
    required this.key,
    required this.line1,
    this.label = '',
    this.line2 = '',
    this.city,
    this.state,
    this.country,
    this.pincode = '',
    this.isMain = false,
  });

  AddressDraft copyWith({
    int? key,
    String? label,
    String? line1,
    String? line2,
    CityModel? city,
    StateModel? state,
    CountryModel? country,
    String? pincode,
    bool? isMain,
  }) => AddressDraft(
    key: key ?? this.key,
    label: label ?? this.label,
    line1: line1 ?? this.line1,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    country: country ?? this.country,
    pincode: pincode ?? this.pincode,
    isMain: isMain ?? this.isMain,
  );

  @override
  AddressDraft withMain(bool value) => copyWith(isMain: value);

  ClientAddress toModel() => ClientAddress(
    label: label,
    line1: line1,
    line2: line2,
    pincode: pincode,
    cityId: city?.id ?? 0,
    stateId: state?.id ?? city?.stateId ?? 0,
    countryId: country?.id ?? 0,
    cityName: city?.name ?? '',
    stateName: state?.name ?? city?.stateName ?? '',
    countryName: country?.name ?? '',
    isPrimary: isMain,
  );

  String get title => label.isNotEmpty ? label : line1;

  String get summary => [
    line1,
    line2,
    city?.name ?? '',
    state?.name ?? '',
    pincode,
    country?.name ?? '',
  ].where((part) => part.trim().isNotEmpty).join(', ');

  @override
  List<Object?> get props => [
    key,
    label,
    line1,
    line2,
    city,
    state,
    country,
    pincode,
    isMain,
  ];
}

class ContactDraft extends Equatable implements MainFlaggable {
  @override
  final int key;
  final String name;
  final String phoneNumber;
  final String role;
  @override
  final bool isMain;

  const ContactDraft({
    required this.key,
    required this.name,
    required this.phoneNumber,
    this.role = '',
    this.isMain = false,
  });

  ContactDraft copyWith({
    int? key,
    String? name,
    String? phoneNumber,
    String? role,
    bool? isMain,
  }) => ContactDraft(
    key: key ?? this.key,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    role: role ?? this.role,
    isMain: isMain ?? this.isMain,
  );

  @override
  ContactDraft withMain(bool value) => copyWith(isMain: value);

  ClientContact toModel() => ClientContact(
    name: name,
    phoneNumber: phoneNumber,
    role: role,
    isPrimary: isMain,
  );

  @override
  List<Object?> get props => [key, name, phoneNumber, role, isMain];
}

class TransportDraft extends Equatable implements MainFlaggable {
  @override
  final int key;
  final String name;
  @override
  final bool isMain;

  const TransportDraft({
    required this.key,
    required this.name,
    this.isMain = false,
  });

  TransportDraft copyWith({int? key, String? name, bool? isMain}) =>
      TransportDraft(
        key: key ?? this.key,
        name: name ?? this.name,
        isMain: isMain ?? this.isMain,
      );

  @override
  TransportDraft withMain(bool value) => copyWith(isMain: value);

  TransportAgency toModel() => TransportAgency(name: name, isPrimary: isMain);

  @override
  List<Object?> get props => [key, name, isMain];
}

class ClientFormState extends Equatable {
  final ClientFormStep step;
  final ClientFormStatus status;
  final String name;
  final String phoneNumber;
  final String gstNumber;
  final List<AddressDraft> addresses;
  final List<ContactDraft> contacts;
  final List<TransportDraft> transportAgencies;
  final String? errorMessage;

  const ClientFormState({
    this.step = ClientFormStep.details,
    this.status = ClientFormStatus.editing,
    this.name = '',
    this.phoneNumber = '',
    this.gstNumber = '',
    this.addresses = const [],
    this.contacts = const [],
    this.transportAgencies = const [],
    this.errorMessage,
  });

  ClientFormState copyWith({
    ClientFormStep? step,
    ClientFormStatus? status,
    String? name,
    String? phoneNumber,
    String? gstNumber,
    List<AddressDraft>? addresses,
    List<ContactDraft>? contacts,
    List<TransportDraft>? transportAgencies,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClientFormState(
      step: step ?? this.step,
      status: status ?? this.status,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      addresses: addresses ?? this.addresses,
      contacts: contacts ?? this.contacts,
      transportAgencies: transportAgencies ?? this.transportAgencies,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  int get stepIndex => ClientFormStep.values.indexOf(step);

  int get stepCount => ClientFormStep.values.length;

  bool get isFirstStep => step == ClientFormStep.details;

  bool get isLastStep => step == ClientFormStep.transport;

  bool get isSubmitting => status == ClientFormStatus.submitting;

  bool get hasAnyInput =>
      name.trim().isNotEmpty ||
      phoneNumber.trim().isNotEmpty ||
      gstNumber.trim().isNotEmpty ||
      addresses.isNotEmpty ||
      contacts.isNotEmpty ||
      transportAgencies.isNotEmpty;

  @override
  List<Object?> get props => [
    step,
    status,
    name,
    phoneNumber,
    gstNumber,
    addresses,
    contacts,
    transportAgencies,
    errorMessage,
  ];
}
