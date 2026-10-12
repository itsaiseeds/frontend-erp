import 'package:equatable/equatable.dart';

import '../../../clients/data/models/child_org.dart';
import '../../../clients/data/models/client_address.dart';
import '../../../clients/data/models/transport_agency.dart';
import '../../../products/data/models/cart_line.dart';
import '../../data/models/order.dart';

enum EditOrderStatus { initial, loading, ready, failure }

/// Review the seeded cart first, then the delivery fields -- same shape as
/// [CheckoutStep] in `checkout_state.dart`, so the flow feels identical to
/// booking a fresh order.
enum EditOrderStep { review, delivery }

class EditOrderState extends Equatable {
  final EditOrderStatus status;
  final EditOrderStep step;

  /// The order being edited, kept around to read its client/current
  /// "deliver elsewhere" place and to know what was originally booked.
  final Order order;

  final List<CartLine> lines;

  /// Link rows for the order's client, fetched once on open -- same calls
  /// [CheckoutCubit.selectClient] makes, since the list payload the order
  /// came from carries no link ids to pre-select from.
  final List<ClientAddress> addresses;
  final List<TransportAgency> agencies;
  final bool isLoadingLinks;

  /// Null means "unchanged" -- the picker shows a value, but nothing is sent
  /// for this field unless the sales person actually picks something.
  final ClientAddress? address;
  final TransportAgency? agency;

  final DateTime? expectedDeliveryDate;

  /// A new remark to add, never the order's existing comments -- the backend
  /// appends whatever is sent here as a new line rather than replacing them.
  final String comment;

  /// Whether the "Deliver to a different place" section is open. Pre-set
  /// from the order: it already has a place, or it does not.
  final bool deliversElsewhere;
  final List<ChildOrg> deliveryPlaces;
  final bool isLoadingDeliveryPlaces;

  /// Null means "unchanged" -- the order's own [Order.bookedFor] keeps
  /// applying unless a different existing place is picked here.
  final ChildOrg? deliveryPlace;

  final bool isSubmitting;
  final String? errorMessage;
  final String? validationMessage;

  const EditOrderState({
    this.status = EditOrderStatus.initial,
    this.step = EditOrderStep.review,
    required this.order,
    this.lines = const [],
    this.addresses = const [],
    this.agencies = const [],
    this.isLoadingLinks = false,
    this.address,
    this.agency,
    this.expectedDeliveryDate,
    this.comment = '',
    this.deliversElsewhere = false,
    this.deliveryPlaces = const [],
    this.isLoadingDeliveryPlaces = false,
    this.deliveryPlace,
    this.isSubmitting = false,
    this.errorMessage,
    this.validationMessage,
  });

  EditOrderState copyWith({
    EditOrderStatus? status,
    EditOrderStep? step,
    List<CartLine>? lines,
    List<ClientAddress>? addresses,
    List<TransportAgency>? agencies,
    bool? isLoadingLinks,
    ClientAddress? address,
    bool clearAddress = false,
    TransportAgency? agency,
    bool clearAgency = false,
    DateTime? expectedDeliveryDate,
    String? comment,
    bool? deliversElsewhere,
    List<ChildOrg>? deliveryPlaces,
    bool? isLoadingDeliveryPlaces,
    ChildOrg? deliveryPlace,
    bool clearDeliveryPlace = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? validationMessage,
    bool clearValidation = false,
  }) {
    return EditOrderState(
      status: status ?? this.status,
      step: step ?? this.step,
      order: order,
      lines: lines ?? this.lines,
      addresses: addresses ?? this.addresses,
      agencies: agencies ?? this.agencies,
      isLoadingLinks: isLoadingLinks ?? this.isLoadingLinks,
      address: clearAddress ? null : address ?? this.address,
      agency: clearAgency ? null : agency ?? this.agency,
      expectedDeliveryDate:
          expectedDeliveryDate ?? this.expectedDeliveryDate,
      comment: comment ?? this.comment,
      deliversElsewhere: deliversElsewhere ?? this.deliversElsewhere,
      deliveryPlaces: deliveryPlaces ?? this.deliveryPlaces,
      isLoadingDeliveryPlaces:
          isLoadingDeliveryPlaces ?? this.isLoadingDeliveryPlaces,
      deliveryPlace: clearDeliveryPlace
          ? null
          : deliveryPlace ?? this.deliveryPlace,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      validationMessage: clearValidation
          ? null
          : validationMessage ?? this.validationMessage,
    );
  }

  bool get isLoading => status == EditOrderStatus.loading;

  num get linesTotal =>
      lines.fold<num>(0, (total, line) => total + line.lineTotal);

  int get lineItemCount => lines.length;

  bool get canSubmit => lines.isNotEmpty && !isSubmitting;

  @override
  List<Object?> get props => [
    status,
    step,
    order,
    lines,
    addresses,
    agencies,
    isLoadingLinks,
    address,
    agency,
    expectedDeliveryDate,
    comment,
    deliversElsewhere,
    deliveryPlaces,
    isLoadingDeliveryPlaces,
    deliveryPlace,
    isSubmitting,
    errorMessage,
    validationMessage,
  ];
}
