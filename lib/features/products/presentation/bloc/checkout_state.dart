import 'package:equatable/equatable.dart';

import '../../../../core/models/city_model.dart';
import '../../../../core/models/country_model.dart';
import '../../../../core/models/state_model.dart';
import '../../../clients/data/models/child_org.dart';
import '../../../clients/data/models/client.dart';
import '../../../clients/data/models/client_address.dart';
import '../../../clients/data/models/sales_person_option.dart';
import '../../../clients/data/models/transport_agency.dart';

/// The in-progress fields for a brand-new "Delivery To" place -- only used
/// while [CheckoutState.isAddingNewDeliveryPlace] is true. Kept as one value
/// object so the cubit can replace it wholesale per keystroke/pick without a
/// long list of individual state fields.
class NewDeliveryPlaceDraft extends Equatable {
  final String partyName;
  final String villageName;
  final String line1;
  final String line2;
  final String district;
  final String pincode;
  final CountryModel? country;
  final StateModel? state;
  final CityModel? city;
  final String transportName;
  final String contactNumber;

  const NewDeliveryPlaceDraft({
    this.partyName = '',
    this.villageName = '',
    this.line1 = '',
    this.line2 = '',
    this.district = '',
    this.pincode = '',
    this.country,
    this.state,
    this.city,
    this.transportName = '',
    this.contactNumber = '',
  });

  NewDeliveryPlaceDraft copyWith({
    String? partyName,
    String? villageName,
    String? line1,
    String? line2,
    String? district,
    String? pincode,
    CountryModel? country,
    bool clearCountry = false,
    StateModel? state,
    bool clearState = false,
    CityModel? city,
    bool clearCity = false,
    String? transportName,
    String? contactNumber,
  }) {
    return NewDeliveryPlaceDraft(
      partyName: partyName ?? this.partyName,
      villageName: villageName ?? this.villageName,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      district: district ?? this.district,
      pincode: pincode ?? this.pincode,
      country: clearCountry ? null : country ?? this.country,
      state: clearState ? null : state ?? this.state,
      city: clearCity ? null : city ?? this.city,
      transportName: transportName ?? this.transportName,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }

  bool get isComplete =>
      partyName.trim().isNotEmpty &&
      villageName.trim().isNotEmpty &&
      line1.trim().isNotEmpty &&
      country != null &&
      state != null &&
      city != null;

  @override
  List<Object?> get props => [
    partyName,
    villageName,
    line1,
    line2,
    district,
    pincode,
    country,
    state,
    city,
    transportName,
    contactNumber,
  ];
}

enum CheckoutStatus { initial, loading, ready, failure }

/// Review the cart first, then fill in delivery -- the order summary only
/// appears once an address is chosen, as in the reference flow.
enum CheckoutStep { review, delivery }

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final CheckoutStep step;

  /// Whether the caller is an app admin who may book on behalf of another
  /// sales person -- gates whether the "Book for" picker shows at all.
  final bool isAdmin;

  /// Populated only for an admin; the person currently being booked for is
  /// [bookingFor] (null means booking as the admin themselves).
  final List<SalesPersonOption> salesPersons;
  final SalesPersonOption? bookingFor;
  final bool isLoadingSalesPersons;

  final List<Client> clients;
  final Client? client;

  /// Link rows for the selected client, fetched per client -- the client list
  /// payload carries no link ids.
  final List<ClientAddress> addresses;
  final List<TransportAgency> agencies;
  final bool isLoadingLinks;
  final ClientAddress? address;
  final TransportAgency? agency;
  final String comments;

  /// Whether the "Deliver to a different place" section is open at all.
  /// Off by default: the order delivers to the client's own address.
  final bool deliversElsewhere;

  /// The client's existing "Delivery To" places, fetched lazily once
  /// [deliversElsewhere] is turned on. Empty until then.
  final List<ChildOrg> deliveryPlaces;
  final bool isLoadingDeliveryPlaces;

  /// Picked from [deliveryPlaces], or null while adding a brand-new one.
  final ChildOrg? deliveryPlace;

  /// True while the inline "add a new delivery place" form is open, instead
  /// of (or before) picking an existing [deliveryPlace].
  final bool isAddingNewDeliveryPlace;
  final NewDeliveryPlaceDraft newDeliveryPlace;
  final String? deliveryPlaceError;

  final bool isSubmitting;
  final String? errorMessage;
  final String? validationMessage;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.step = CheckoutStep.review,
    this.isAdmin = false,
    this.salesPersons = const [],
    this.bookingFor,
    this.isLoadingSalesPersons = false,
    this.clients = const [],
    this.client,
    this.addresses = const [],
    this.agencies = const [],
    this.isLoadingLinks = false,
    this.address,
    this.agency,
    this.comments = '',
    this.deliversElsewhere = false,
    this.deliveryPlaces = const [],
    this.isLoadingDeliveryPlaces = false,
    this.deliveryPlace,
    this.isAddingNewDeliveryPlace = false,
    this.newDeliveryPlace = const NewDeliveryPlaceDraft(),
    this.deliveryPlaceError,
    this.isSubmitting = false,
    this.errorMessage,
    this.validationMessage,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    CheckoutStep? step,
    bool? isAdmin,
    List<SalesPersonOption>? salesPersons,
    SalesPersonOption? bookingFor,
    bool clearBookingFor = false,
    bool? isLoadingSalesPersons,
    List<Client>? clients,
    Client? client,
    bool clearClient = false,
    List<ClientAddress>? addresses,
    List<TransportAgency>? agencies,
    bool? isLoadingLinks,
    ClientAddress? address,
    bool clearAddress = false,
    TransportAgency? agency,
    bool clearAgency = false,
    String? comments,
    bool? deliversElsewhere,
    List<ChildOrg>? deliveryPlaces,
    bool? isLoadingDeliveryPlaces,
    ChildOrg? deliveryPlace,
    bool clearDeliveryPlace = false,
    bool? isAddingNewDeliveryPlace,
    NewDeliveryPlaceDraft? newDeliveryPlace,
    String? deliveryPlaceError,
    bool clearDeliveryPlaceError = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? validationMessage,
    bool clearValidation = false,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      step: step ?? this.step,
      isAdmin: isAdmin ?? this.isAdmin,
      salesPersons: salesPersons ?? this.salesPersons,
      bookingFor: clearBookingFor ? null : bookingFor ?? this.bookingFor,
      isLoadingSalesPersons:
          isLoadingSalesPersons ?? this.isLoadingSalesPersons,
      clients: clients ?? this.clients,
      client: clearClient ? null : client ?? this.client,
      addresses: addresses ?? this.addresses,
      agencies: agencies ?? this.agencies,
      isLoadingLinks: isLoadingLinks ?? this.isLoadingLinks,
      address: clearAddress ? null : address ?? this.address,
      agency: clearAgency ? null : agency ?? this.agency,
      comments: comments ?? this.comments,
      deliversElsewhere: deliversElsewhere ?? this.deliversElsewhere,
      deliveryPlaces: deliveryPlaces ?? this.deliveryPlaces,
      isLoadingDeliveryPlaces:
          isLoadingDeliveryPlaces ?? this.isLoadingDeliveryPlaces,
      deliveryPlace: clearDeliveryPlace
          ? null
          : deliveryPlace ?? this.deliveryPlace,
      isAddingNewDeliveryPlace:
          isAddingNewDeliveryPlace ?? this.isAddingNewDeliveryPlace,
      newDeliveryPlace: newDeliveryPlace ?? this.newDeliveryPlace,
      deliveryPlaceError: clearDeliveryPlaceError
          ? null
          : deliveryPlaceError ?? this.deliveryPlaceError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      validationMessage: clearValidation
          ? null
          : validationMessage ?? this.validationMessage,
    );
  }

  bool get isLoading => status == CheckoutStatus.loading;

  /// Whether the "deliver elsewhere" section is itself satisfied: off
  /// entirely, an existing place picked, or a new one fully filled in.
  bool get isDeliveryPlaceResolved {
    if (!deliversElsewhere) return true;
    if (isAddingNewDeliveryPlace) return newDeliveryPlace.isComplete;
    return deliveryPlace != null;
  }

  bool get canSubmit =>
      client != null &&
      address != null &&
      address!.id != 0 &&
      isDeliveryPlaceResolved &&
      !isSubmitting;

  /// The order summary and Place order button appear only once delivery is
  /// answered, so the sheet does not show a total nobody can act on yet.
  bool get isDeliveryResolved =>
      client != null && address != null && address!.id != 0;

  @override
  List<Object?> get props => [
    status,
    step,
    isAdmin,
    salesPersons,
    bookingFor,
    isLoadingSalesPersons,
    clients,
    client,
    addresses,
    agencies,
    isLoadingLinks,
    address,
    agency,
    comments,
    deliversElsewhere,
    deliveryPlaces,
    isLoadingDeliveryPlaces,
    deliveryPlace,
    isAddingNewDeliveryPlace,
    newDeliveryPlace,
    deliveryPlaceError,
    isSubmitting,
    errorMessage,
    validationMessage,
  ];
}
