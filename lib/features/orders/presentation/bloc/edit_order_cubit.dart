import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../clients/data/clients_repository.dart';
import '../../../clients/data/models/child_org.dart';
import '../../../clients/data/models/client_address.dart';
import '../../../clients/data/models/transport_agency.dart';
import '../../../products/data/models/cart_line.dart';
import '../../../products/data/models/product_packaging.dart';
import '../../data/models/order.dart';
import '../../data/orders_repository.dart';
import 'edit_order_state.dart';

class EditOrderCubit extends SafeCubit<EditOrderState> {
  final ClientsRepository _clientsRepository;
  final OrdersRepository _ordersRepository;

  EditOrderCubit({
    required ClientsRepository clientsRepository,
    required OrdersRepository ordersRepository,
    required Order order,
  }) : _clientsRepository = clientsRepository,
       _ordersRepository = ordersRepository,
       super(
         EditOrderState(
           order: order,
           lines: _seedLines(order),
           expectedDeliveryDate: order.expectedDeliveryDate,
           deliversElsewhere: order.bookedFor != null,
         ),
       );

  /// Each of the order's existing lines, rebuilt into a [CartLine] so the
  /// review step can show and restep them exactly like the cart on a fresh
  /// booking. [OrderPackaging] already carries the packaging's own public id
  /// (not an order-line id -- confirmed against `packaging_payload` on the
  /// backend), so it maps straight onto [ProductPackaging.publicId]; fields
  /// the order line does not carry (stage name, description items) are left
  /// at their defaults, which only affects cosmetic details this screen does
  /// not show.
  static List<CartLine> _seedLines(Order order) {
    return [
      for (final OrderPackaging line in order.packagings)
        CartLine(
          packaging: ProductPackaging(
            publicId: line.publicId,
            productPublicId: line.productPublicId,
            productName: line.productName,
            imageUrl: line.imageUrl,
            packetWeight: line.packetWeight,
            packets: line.packets,
            totalWeight: line.totalWeight,
            sellingPrice: line.sellingPrice,
          ),
          quantity: line.quantity,
        ),
    ];
  }

  Future<void> loadLinks() async {
    emit(state.copyWith(status: EditOrderStatus.loading, isLoadingLinks: true));

    try {
      final List<ClientAddress> addresses = await _clientsRepository
          .fetchAddresses(state.order.client.publicId);
      final List<TransportAgency> agencies = await _clientsRepository
          .fetchTransportAgencies(state.order.client.publicId);

      emit(
        state.copyWith(
          status: EditOrderStatus.ready,
          addresses: addresses,
          agencies: agencies,
          isLoadingLinks: false,
        ),
      );

      if (state.deliversElsewhere) await _loadDeliveryPlaces();
    } on ApiException catch (e) {
      _emitFailure(e.message);
    } catch (e) {
      AppLogger.session('failed to load delivery options for edit: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  Future<void> _loadDeliveryPlaces() async {
    emit(state.copyWith(isLoadingDeliveryPlaces: true));
    try {
      final List<ChildOrg> places = await _clientsRepository.fetchChildOrgs(
        state.order.client.publicId,
      );
      emit(
        state.copyWith(
          deliveryPlaces: places,
          isLoadingDeliveryPlaces: false,
        ),
      );
    } catch (e) {
      AppLogger.session('failed to load delivery places for edit: $e');
      emit(state.copyWith(isLoadingDeliveryPlaces: false));
    }
  }

  void addLine(ProductPackaging packaging) {
    final List<CartLine> next = [...state.lines];
    final int index = next.indexWhere(
      (line) => line.packaging.publicId == packaging.publicId,
    );

    if (index == -1) {
      next.add(CartLine(packaging: packaging));
    } else {
      next[index] = next[index].copyWith(quantity: next[index].quantity + 1);
    }

    emit(state.copyWith(lines: next));
  }

  void removeLine(ProductPackaging packaging) {
    final List<CartLine> next = [...state.lines];
    final int index = next.indexWhere(
      (line) => line.packaging.publicId == packaging.publicId,
    );
    if (index == -1) return;

    if (next[index].quantity <= 1) {
      next.removeAt(index);
    } else {
      next[index] = next[index].copyWith(quantity: next[index].quantity - 1);
    }

    emit(state.copyWith(lines: next));
  }

  /// Replaces the whole cart in one go -- what the "add products" picker
  /// hands back on Done, since it edits a full copy of the selection rather
  /// than issuing one add/remove per change.
  /// Typed directly into the stepper's count rather than one tap per bag.
  void setLineQuantity(ProductPackaging packaging, int quantity) {
    if (quantity < 1) return;

    final List<CartLine> next = [...state.lines];
    final int index = next.indexWhere(
      (line) => line.packaging.publicId == packaging.publicId,
    );
    if (index == -1) return;

    next[index] = next[index].copyWith(quantity: quantity);
    emit(state.copyWith(lines: next));
  }

  void setLines(List<CartLine> lines) => emit(state.copyWith(lines: lines));

  void selectAddress(ClientAddress address) =>
      emit(state.copyWith(address: address, clearValidation: true));

  void selectAgency(TransportAgency agency) =>
      emit(state.copyWith(agency: agency));

  Future<void> setDeliversElsewhere(bool value) async {
    if (state.deliversElsewhere == value) return;

    emit(
      state.copyWith(
        deliversElsewhere: value,
        clearDeliveryPlace: true,
        clearValidation: true,
      ),
    );

    if (value && state.deliveryPlaces.isEmpty) await _loadDeliveryPlaces();
  }

  void selectDeliveryPlace(ChildOrg place) =>
      emit(state.copyWith(deliveryPlace: place, clearValidation: true));

  void setExpectedDeliveryDate(DateTime date) =>
      emit(state.copyWith(expectedDeliveryDate: date));

  void updateComment(String value) => emit(state.copyWith(comment: value));

  void goToDelivery() => emit(state.copyWith(step: EditOrderStep.delivery));

  void backToReview() => emit(state.copyWith(step: EditOrderStep.review));

  Future<bool> submit() async {
    if (state.lines.isEmpty) {
      emit(
        state.copyWith(
          validationMessage: AppStrings.VALIDATION_LINES_REQUIRED,
        ),
      );
      return false;
    }
    if (state.deliversElsewhere && state.deliveryPlace == null) {
      emit(
        state.copyWith(
          validationMessage: AppStrings.VALIDATION_DELIVERY_PLACE_REQUIRED,
        ),
      );
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await _ordersRepository.editOrder(
        publicId: state.order.publicId,
        clientAddressId: state.address?.id,
        clientTransportAgencyId: state.agency?.isPrivateDispatch ?? false
            ? null
            : state.agency?.id,
        expectedDeliveryDate: state.expectedDeliveryDate == null
            ? null
            : _isoDate(state.expectedDeliveryDate!),
        addComment: state.comment,
        lines: state.lines,
        bookedFor: _bookedForPayload(),
      );

      emit(state.copyWith(isSubmitting: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
      return false;
    } catch (e) {
      AppLogger.session('failed to edit order: $e');
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
      return false;
    }
  }

  /// Only sent when the sales person actually picked a different existing
  /// place here -- leaving [EditOrderState.deliveryPlace] null keeps the
  /// order's current `booked_for` (or lack of one) exactly as it was.
  Map<String, dynamic>? _bookedForPayload() {
    final ChildOrg? picked = state.deliveryPlace;
    return picked == null ? null : {'id': picked.id};
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _emitFailure(String message) {
    final String trimmed = message.trim();
    emit(
      state.copyWith(
        status: EditOrderStatus.failure,
        isLoadingLinks: false,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
