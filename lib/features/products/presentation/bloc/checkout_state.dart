import 'package:equatable/equatable.dart';

import '../../../clients/data/models/client.dart';
import '../../../clients/data/models/client_address.dart';
import '../../../clients/data/models/sales_person_option.dart';
import '../../../clients/data/models/transport_agency.dart';

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
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      validationMessage: clearValidation
          ? null
          : validationMessage ?? this.validationMessage,
    );
  }

  bool get isLoading => status == CheckoutStatus.loading;

  bool get canSubmit =>
      client != null && address != null && address!.id != 0 && !isSubmitting;

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
    isSubmitting,
    errorMessage,
    validationMessage,
  ];
}
