import '../../../../core/constants/app_strings.dart';

/// The seven order lifecycle codes the backend sends, plus a fallback so an
/// unknown code renders as itself rather than breaking the card.
enum OrderStatus {
  booked,
  underReview,
  confirmed,
  dispatched,
  delivered,
  onHold,
  rejected,
  unknown,
}

class OrderStatusX {
  OrderStatusX._();

  static const String BOOKED = 'BOOKED';
  static const String UNDER_REVIEW = 'UNDER_REVIEW';
  static const String CONFIRMED = 'CONFIRMED';
  static const String DISPATCHED = 'DISPATCHED';
  static const String DELIVERED = 'DELIVERED';
  static const String ON_HOLD = 'ON_HOLD';
  static const String REJECTED = 'REJECTED';

  static OrderStatus fromRaw(String raw) {
    switch (raw.trim().toUpperCase()) {
      case BOOKED:
        return OrderStatus.booked;
      case UNDER_REVIEW:
        return OrderStatus.underReview;
      case CONFIRMED:
        return OrderStatus.confirmed;
      case DISPATCHED:
        return OrderStatus.dispatched;
      case DELIVERED:
        return OrderStatus.delivered;
      case ON_HOLD:
        return OrderStatus.onHold;
      case REJECTED:
        return OrderStatus.rejected;
      default:
        return OrderStatus.unknown;
    }
  }

  static String labelOf(OrderStatus status) {
    switch (status) {
      case OrderStatus.booked:
        return AppStrings.ORDER_STATUS_BOOKED;
      case OrderStatus.underReview:
        return AppStrings.ORDER_STATUS_UNDER_REVIEW;
      case OrderStatus.confirmed:
        return AppStrings.ORDER_STATUS_CONFIRMED;
      case OrderStatus.dispatched:
        return AppStrings.ORDER_STATUS_DISPATCHED;
      case OrderStatus.delivered:
        return AppStrings.ORDER_STATUS_DELIVERED;
      case OrderStatus.onHold:
        return AppStrings.ORDER_STATUS_ON_HOLD;
      case OrderStatus.rejected:
        return AppStrings.ORDER_STATUS_REJECTED;
      case OrderStatus.unknown:
        return AppStrings.ORDER_STATUS_UNKNOWN;
    }
  }
}
