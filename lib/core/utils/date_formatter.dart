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
  static final DateFormat _monthShort = DateFormat('MMM');

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

  /// "10:57 PM" -- the clock time alone, for a row already filed under a
  /// date heading where repeating the date would be noise.
  static String timeOfDay(DateTime? value) =>
      value == null ? AppStrings.ORDER_NO_DATE : _time.format(_ist(value));

  /// The IST calendar day an instant falls on, for grouping a list by date.
  ///
  /// Dates are compared on this rather than the raw instant: two stamps
  /// hours apart can still be the same working day, and a phone in another
  /// zone must not split them.
  static DateTime istDay(DateTime value) {
    final DateTime ist = _ist(value);
    return DateTime(ist.year, ist.month, ist.day);
  }

  /// A heading for a group of rows: "Today", "Yesterday", then the date
  /// itself -- "30th Sept", carrying the year only when it is not the
  /// current one, since the year is noise for anything recent.
  static String relativeDayHeading(DateTime value, {DateTime? now}) {
    final DateTime today = istDay(now ?? DateTime.now());
    final DateTime day = istDay(value);
    final int difference = today.difference(day).inDays;

    if (difference == 0) return AppStrings.DATE_TODAY;
    if (difference == 1) return AppStrings.DATE_YESTERDAY;

    final String label = '${_ordinal(day.day)} ${_monthShort.format(day)}';
    return day.year == today.year ? label : '$label ${day.year}';
  }

  /// 1st, 2nd, 3rd, 4th -- 11th to 13th are the exceptions that make a
  /// naive last-digit rule wrong.
  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  static DateTime _ist(DateTime value) => value.toUtc().add(IST_OFFSET);
}
