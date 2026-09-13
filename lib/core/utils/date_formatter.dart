import 'package:intl/intl.dart';

import '../constants/app_strings.dart';

class DateFormatter {
  DateFormatter._();

  /// The backend stamps times in UTC and the business runs on IST, so the
  /// offset is applied explicitly rather than trusting the device clock -- a
  /// phone set to another zone would otherwise show a different hour.
  static const Duration IST_OFFSET = Duration(hours: 5, minutes: 30);

  static final DateFormat _day = DateFormat('d MMM yyyy');
  static final DateFormat _dayShort = DateFormat('d MMM');
  static final DateFormat _time = DateFormat('h:mm a');

  /// "13 Sep 2026" from an instant, shifted into IST.
  static String day(DateTime? value) =>
      value == null ? AppStrings.ORDER_NO_DATE : _day.format(_ist(value));

  /// "13 Sep" -- for a card, where the year is usually noise.
  static String dayShort(DateTime? value) =>
      value == null ? AppStrings.ORDER_NO_DATE : _dayShort.format(_ist(value));

  /// A calendar date with no instant behind it (an expected delivery day) is
  /// printed as sent -- applying a zone offset would move it a day.
  static String calendarDay(DateTime? value) =>
      value == null ? AppStrings.ORDER_NO_DATE : _day.format(value);

  /// "13 Sep, 10:57 PM IST" -- a timestamp a sales person can act on.
  static String dayTime(DateTime? value) {
    if (value == null) return AppStrings.ORDER_NO_DATE;
    final DateTime ist = _ist(value);
    return '${_dayShort.format(ist)}, ${_time.format(ist)} '
        '${AppStrings.TIMEZONE_IST}';
  }

  /// "13 Sep 2026, 10:57 PM IST" -- the same stamp with the year, for a detail
  /// screen where there is room for it.
  static String dayTimeFull(DateTime? value) {
    if (value == null) return AppStrings.ORDER_NO_DATE;
    final DateTime ist = _ist(value);
    return '${_day.format(ist)}, ${_time.format(ist)} '
        '${AppStrings.TIMEZONE_IST}';
  }

  static DateTime _ist(DateTime value) => value.toUtc().add(IST_OFFSET);
}
