import 'package:intl/intl.dart';

import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/models/return_order.dart';
import '../../data/models/return_order_draft_item.dart';
import '../../data/models/return_order_prefill.dart';
import '../../data/return_orders_repository.dart';
import 'return_order_form_state.dart';

/// Builds and raises a return against one dispatched order.
///
/// The screen holds the prefill and the draft lines: the challan lines say what
/// is still returnable on each product and weight, and the draft is what the
/// salesperson has picked off them.
class ReturnOrderFormCubit extends SafeCubit<ReturnOrderFormState> {
  final ReturnOrdersRepository _repository;
  final String _orderPublicId;

  ReturnOrderFormCubit({
    required ReturnOrdersRepository repository,
    required String orderPublicId,
  }) : _repository = repository,
       _orderPublicId = orderPublicId,
       super(ReturnOrderFormState(returnDate: ReturnOrderFormCubit.today()));

  /// A return is recorded on the day goods come back, so the field opens on
  /// today and cannot be pushed into the future.
  static DateTime today() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Two years back is far enough to cover goods sitting with a client while a
  /// claim is sorted out, and short enough to keep the calendar usable.
  static DateTime earliestDate() {
    final DateTime now = today();
    return DateTime(now.year - 2, now.month, now.day);
  }

  static final DateFormat _requestDate = DateFormat('yyyy-MM-dd');

  Future<void> load() async {
    emit(state.copyWith(status: ReturnOrderFormStatus.loading, clearError: true));

    try {
      final ReturnOrderPrefill prefill = await _repository.fetchPrefill(
        _orderPublicId,
      );

      emit(
        state.copyWith(
          status: ReturnOrderFormStatus.ready,
          prefill: prefill,
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ReturnOrderFormStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      AppLogger.session('failed to load return prefill: $e');
      emit(
        state.copyWith(
          status: ReturnOrderFormStatus.failure,
          errorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }
  }

  /// The product/weight pairs already on a card. The API enforces uniqueness on
  /// exactly this pair, so the same pair cannot appear twice.
  Set<String> get _usedKeys => state.items
      .map((item) => '${item.productPublicId}|${item.weightKey}')
      .toSet();

  /// Products with at least one weight still unclaimed. A product whose every
  /// weight is already on a card drops out of the picker rather than offering
  /// a line the API would reject.
  List<ReturnOrderProduct> get availableProducts {
    final ReturnOrderPrefill? prefill = state.prefill;
    if (prefill == null) return const [];

    final Set<String> used = _usedKeys;
    return prefill.products
        .where(
          (product) => product.sortedLines.any(
            (line) =>
                line.isReturnable &&
                !used.contains('${product.publicId}|${line.weightKey}'),
          ),
        )
        .toList(growable: false);
  }

  bool get hasMoreProducts => availableProducts.isNotEmpty;

  void setReturnDate(DateTime date) {
    final DateTime first = earliestDate();
    final DateTime last = today();
    final DateTime day = DateTime(date.year, date.month, date.day);

    if (day.isBefore(first) || day.isAfter(last)) return;
    emit(state.copyWith(returnDate: day));
  }

  /// Adds a card for a product, lightest unclaimed weight first.
  ///
  /// Returns the reason it could not, so the screen can say why rather than
  /// silently doing nothing.
  String? addProduct(ReturnOrderProduct product) {
    final ReturnOrderPrefillLine? line = _nextFreeLine(product.publicId);
    if (line == null) return AppStrings.RETURN_ORDER_ALL_WEIGHTS_ADDED;

    emit(
      state.copyWith(
        items: [...state.items, _draftFrom(product, line)],
        clearError: true,
      ),
    );
    return null;
  }

  /// Adds a second card for a product that was dispatched in more than one
  /// weight -- the only other line the API will accept for that product.
  String? addAnotherWeight(int index) {
    final ReturnOrderDraftItem? item = _itemAt(index);
    if (item == null) return AppStrings.RETURN_ORDER_ALL_WEIGHTS_ADDED;

    final ReturnOrderProduct? product = _productFor(item.productPublicId);
    if (product == null) return AppStrings.RETURN_ORDER_ALL_WEIGHTS_ADDED;

    final ReturnOrderPrefillLine? line = _nextFreeLine(product.publicId);
    if (line == null) return AppStrings.RETURN_ORDER_ALL_WEIGHTS_ADDED;

    emit(
      state.copyWith(
        items: [...state.items, _draftFrom(product, line)],
        clearError: true,
      ),
    );
    return null;
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final List<ReturnOrderDraftItem> next = [...state.items]..removeAt(index);
    emit(state.copyWith(items: next, clearError: true));
  }

  /// Switches a card to another weight of the same product. Rejected when that
  /// weight is already claimed by another card or has nothing returnable.
  String? setWeight(int index, num weight) {
    final ReturnOrderDraftItem? item = _itemAt(index);
    if (item == null) return AppStrings.RETURN_ORDER_WEIGHT_UNAVAILABLE;

    final ReturnOrderProduct? product = _productFor(item.productPublicId);
    if (product == null) return AppStrings.RETURN_ORDER_WEIGHT_UNAVAILABLE;

    final ReturnOrderPrefillLine? line = product.lineForWeight(weight);
    if (line == null || !line.isReturnable) {
      return AppStrings.RETURN_ORDER_WEIGHT_UNAVAILABLE;
    }

    final bool claimedByAnother = state.items.any(
      (other) =>
          other.productPublicId == item.productPublicId &&
          other.weightKey == line.weightKey,
    );
    if (claimedByAnother) return AppStrings.RETURN_ORDER_WEIGHT_DUPLICATE;

    final List<ReturnOrderDraftItem> next = [...state.items];
    next[index] = item.copyWith(
      packetWeight: line.packetWeight,
      packets: 1,
      pricePerPacket: line.suggestedPricePerPacket,
      maxPackets: line.returnablePackets,
      dispatchedPackets: line.dispatchedPackets,
    );

    emit(state.copyWith(items: next, clearError: true));
    return null;
  }

  /// The count is bounded by what that weight still has returnable, so the
  /// value is clamped rather than trusted -- the field and the stepper both
  /// route through here.
  void setPackets(int index, int packets) {
    final ReturnOrderDraftItem? item = _itemAt(index);
    if (item == null) return;

    final int upper = item.maxPackets > 0 ? item.maxPackets : 1;
    final int value = packets.clamp(1, upper);

    final List<ReturnOrderDraftItem> next = [...state.items];
    next[index] = item.copyWith(packets: value);
    emit(state.copyWith(items: next));
  }

  void setPrice(int index, num price) {
    final ReturnOrderDraftItem? item = _itemAt(index);
    if (item == null) return;
    if (price < 0) return;

    final List<ReturnOrderDraftItem> next = [...state.items];
    next[index] = item.copyWith(pricePerPacket: price);
    emit(state.copyWith(items: next));
  }

  /// Drops every card, for "start again".
  void clearItems() {
    if (state.items.isEmpty) return;
    emit(state.copyWith(items: const [], clearError: true));
  }

  Future<bool> submit() async {
    if (!state.canSubmit) return false;

    emit(state.copyWith(status: ReturnOrderFormStatus.submitting, clearError: true));

    try {
      final ReturnOrder created = await _repository.createReturnOrder(
        orderPublicId: _orderPublicId,
        returnDate: _requestDate.format(state.returnDate),
        items: state.items,
      );

      emit(
        state.copyWith(
          status: ReturnOrderFormStatus.success,
          created: created,
          clearError: true,
        ),
      );
      return true;
    } on ApiException catch (e) {
      // The draft stays on screen: a rejected return is usually a quantity or a
      // line the user has to fix, not something to start over for.
      emit(
        state.copyWith(
          status: ReturnOrderFormStatus.ready,
          errorMessage: e.message,
        ),
      );
      return false;
    } catch (e) {
      AppLogger.session('failed to create return order: $e');
      emit(
        state.copyWith(
          status: ReturnOrderFormStatus.ready,
          errorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
      return false;
    }
  }

  ReturnOrderDraftItem? _itemAt(int index) {
    if (index < 0 || index >= state.items.length) return null;
    return state.items[index];
  }

  ReturnOrderProduct? _productFor(String productPublicId) {
    final ReturnOrderPrefill? prefill = state.prefill;
    if (prefill == null) return null;

    for (final ReturnOrderProduct product in prefill.products) {
      if (product.publicId == productPublicId) return product;
    }
    return null;
  }

  /// The lightest weight of a product that no card has claimed and that still
  /// has something returnable on it.
  ReturnOrderPrefillLine? _nextFreeLine(String productPublicId) {
    final ReturnOrderProduct? product = _productFor(productPublicId);
    if (product == null) return null;

    final Set<String> used = _usedKeys;
    for (final ReturnOrderPrefillLine line in product.sortedLines) {
      if (!line.isReturnable) continue;
      if (used.contains('$productPublicId|${line.weightKey}')) continue;
      return line;
    }
    return null;
  }

  ReturnOrderDraftItem _draftFrom(
    ReturnOrderProduct product,
    ReturnOrderPrefillLine line,
  ) {
    return ReturnOrderDraftItem(
      productPublicId: product.publicId,
      productName: product.name,
      packetWeight: line.packetWeight,
      packets: 1,
      pricePerPacket: line.suggestedPricePerPacket,
      maxPackets: line.returnablePackets,
      dispatchedPackets: line.dispatchedPackets,
    );
  }
}
