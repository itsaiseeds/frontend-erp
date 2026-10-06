import 'package:flutter/material.dart';

import '../../../../core/widgets/inputs/date_time_picker_sheet.dart';

/// A day and a clock time for a trip, as one local instant.
class TripDateTimePicker {
  TripDateTimePicker._();

  static const int _YEARS_BACK = 1;
  static const int _YEARS_FORWARD = 2;

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    DateTime? initial,
    DateTime? firstAllowed,
  }) {
    final DateTime now = DateTime.now();

    return DateTimePickerSheet.show(
      context,
      title: title,
      initial: initial,
      firstAllowed: firstAllowed ?? DateTime(now.year - _YEARS_BACK),
      lastAllowed: DateTime(now.year + _YEARS_FORWARD, 12, 31),
    );
  }
}
