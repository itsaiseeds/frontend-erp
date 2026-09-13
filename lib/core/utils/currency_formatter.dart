import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _whole = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _withPaise = NumberFormat('#,##,##0.00', 'en_IN');

  /// Indian-grouped rupees; paise appear only when the amount has them.
  static String rupees(num value) {
    final String amount = value == value.roundToDouble()
        ? _whole.format(value)
        : _withPaise.format(value);
    return '₹$amount';
  }
}
