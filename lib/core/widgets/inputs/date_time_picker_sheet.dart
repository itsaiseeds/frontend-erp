import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// A day and a clock time picked in one sheet.
///
/// The platform dialogs ask twice -- a date, then a time, each its own modal
/// -- which hides the thing being chosen behind two layers of chrome. Here
/// the running answer stays on screen the whole way, and the shortcuts cover
/// the picks a sales person actually makes: a trip planned for today or
/// tomorrow, starting in the morning.
class DateTimePickerSheet extends StatefulWidget {
  final String title;
  final DateTime? initial;
  final DateTime firstAllowed;
  final DateTime lastAllowed;

  const DateTimePickerSheet({
    super.key,
    required this.title,
    required this.initial,
    required this.firstAllowed,
    required this.lastAllowed,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    DateTime? initial,
    required DateTime firstAllowed,
    required DateTime lastAllowed,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.SURFACE,
      barrierColor: AppColors.OVERLAY,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.SHEET),
        ),
      ),
      builder: (_) => DateTimePickerSheet(
        title: title,
        initial: initial,
        firstAllowed: firstAllowed,
        lastAllowed: lastAllowed,
      ),
    );
  }

  @override
  State<DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<DateTimePickerSheet> {
  static final DateFormat _month = DateFormat('MMMM yyyy');
  static final DateFormat _full = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _clock = DateFormat('h:mm a');

  late DateTime _selected;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final DateTime seed = widget.initial ?? _defaultSeed();
    _selected = seed;
    _visibleMonth = DateTime(seed.year, seed.month);
  }

  /// A trip is planned ahead, so an empty field opens on tomorrow morning
  /// rather than this instant -- the common answer, already filled in.
  DateTime _defaultSeed() {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
    return tomorrow.isBefore(widget.firstAllowed)
        ? widget.firstAllowed
        : tomorrow;
  }

  bool _isAllowed(DateTime day) {
    final DateTime start = DateTime(
      widget.firstAllowed.year,
      widget.firstAllowed.month,
      widget.firstAllowed.day,
    );
    final DateTime end = DateTime(
      widget.lastAllowed.year,
      widget.lastAllowed.month,
      widget.lastAllowed.day,
    );
    return !day.isBefore(start) && !day.isAfter(end);
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selected = DateTime(
        day.year,
        day.month,
        day.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _jumpTo(DateTime day) {
    setState(() {
      _visibleMonth = DateTime(day.year, day.month);
      _selected = DateTime(
        day.year,
        day.month,
        day.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  void _setTime(int hour, int minute) {
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        hour,
        minute,
      );
    });
  }

  Future<void> _pickExactTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
      builder: (context, child) {
        final ThemeData theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.PRIMARY,
              onPrimary: AppColors.TEXT_ON_PRIMARY,
              surface: AppColors.SURFACE,
              onSurface: AppColors.TEXT_PRIMARY,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.SURFACE,
              dialBackgroundColor: AppColors.SURFACE_VARIANT,
              hourMinuteColor: AppColors.PRIMARY_SURFACE,
              hourMinuteTextColor: AppColors.TEXT_PRIMARY,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.XL),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    _setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height *
            AppSizes.DATETIME_SHEET_MAX_HEIGHT,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.SMD12),
          Container(
            width: AppSizes.DATETIME_SHEET_HANDLE_WIDTH,
            height: AppSizes.DATETIME_SHEET_HANDLE_HEIGHT,
            decoration: BoxDecoration(
              color: AppColors.BORDER,
              borderRadius: BorderRadius.circular(AppRadius.FULL),
            ),
          ),
          _Header(title: widget.title, selected: _selected),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.MD16,
                0,
                AppSpacing.MD16,
                AppSpacing.MD16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Shortcuts(
                    today: today,
                    selected: _selected,
                    isAllowed: _isAllowed,
                    onPick: _jumpTo,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  _MonthBar(
                    label: _month.format(_visibleMonth),
                    onPrevious: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
                  ),
                  const SizedBox(height: AppSpacing.SM8),
                  _MonthGrid(
                    month: _visibleMonth,
                    selected: _selected,
                    today: today,
                    isAllowed: _isAllowed,
                    onSelect: _selectDay,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.MD16,
              0,
              AppSpacing.MD16,
              AppSpacing.SMD12,
            ),
            child: _TimeRow(
              selected: _selected,
              clock: _clock,
              onPreset: _setTime,
              onExact: _pickExactTime,
            ),
          ),
          _Footer(
            label: _full.format(_selected),
            onConfirm: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

/// The running answer, kept visible while the date and time are chosen.
class _Header extends StatelessWidget {
  final String title;
  final DateTime selected;

  const _Header({required this.title, required this.selected});

  static final DateFormat _day = DateFormat('EEE, d MMM');
  static final DateFormat _clock = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        AppSpacing.MD16,
        AppSpacing.SM8,
        AppSpacing.MD16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
                const SizedBox(height: AppSpacing.XXS2),
                Text(
                  '${_day.format(selected)}  ·  ${_clock.format(selected)}',
                  style: AppTypography.headingSmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              size: AppSizes.ICON_XL,
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  final DateTime today;
  final DateTime selected;
  final bool Function(DateTime) isAllowed;
  final ValueChanged<DateTime> onPick;

  const _Shortcuts({
    required this.today,
    required this.selected,
    required this.isAllowed,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final DateTime nextWeek = today.add(const Duration(days: 7));

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return Row(
      children: [
        for (final (String label, DateTime day) in [
          (AppStrings.DATETIME_SHEET_TODAY, today),
          (AppStrings.DATETIME_SHEET_TOMORROW, tomorrow),
          (AppStrings.DATETIME_SHEET_NEXT_WEEK, nextWeek),
        ])
          if (isAllowed(day))
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.SM8),
              child: _Pill(
                label: label,
                isSelected: isSameDay(selected, day),
                onTap: () => onPick(day),
              ),
            ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.PRIMARY : AppColors.SURFACE_VARIANT,
      borderRadius: BorderRadius.circular(AppRadius.FULL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.FULL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.SMD12,
            vertical: AppSpacing.SM8,
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected
                  ? AppColors.TEXT_ON_PRIMARY
                  : AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.labelStrong)),
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: AppSizes.ICON_XL,
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right_rounded,
            size: AppSizes.ICON_XL,
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final bool Function(DateTime) isAllowed;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.isAllowed,
    required this.onSelect,
  });

  static const List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime counts Monday as 1; the grid starts on Sunday.
    final int leading = DateTime(month.year, month.month).weekday % 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final String day in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.TEXT_DISABLED,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.XS4),
        // Plain rows rather than a GridView: a shrink-wrapped grid nested in
        // a scroll view puts its own viewport over the cells and swallows
        // the taps meant for them.
        for (int week = 0; week * 7 < leading + daysInMonth; week++)
          Row(
            children: [
              for (int slot = 0; slot < 7; slot++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final int dayNumber = week * 7 + slot - leading + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(
                          height: AppSizes.DATETIME_SHEET_CELL,
                        );
                      }

                      final DateTime day = DateTime(
                        month.year,
                        month.month,
                        dayNumber,
                      );
                      return _DayCell(
                        day: day,
                        isSelected:
                            day.year == selected.year &&
                            day.month == selected.month &&
                            day.day == selected.day,
                        isToday:
                            day.year == today.year &&
                            day.month == today.month &&
                            day.day == today.day,
                        isEnabled: isAllowed(day),
                        onTap: () => onSelect(day),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color text = !isEnabled
        ? AppColors.TEXT_DISABLED
        : isSelected
        ? AppColors.TEXT_ON_PRIMARY
        : AppColors.TEXT_PRIMARY;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSizes.DATETIME_SHEET_CELL,
        child: Center(
          child: Container(
            width: AppSizes.DATETIME_SHEET_CELL,
            height: AppSizes.DATETIME_SHEET_CELL,
          alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.PRIMARY : AppColors.TRANSPARENT,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.PRIMARY)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: AppTypography.bodySmall.copyWith(color: text),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final DateTime selected;
  final DateFormat clock;
  final void Function(int hour, int minute) onPreset;
  final VoidCallback onExact;

  const _TimeRow({
    required this.selected,
    required this.clock,
    required this.onPreset,
    required this.onExact,
  });

  @override
  Widget build(BuildContext context) {
    bool isAt(int hour) => selected.hour == hour && selected.minute == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.DATETIME_SHEET_TIME,
                style: AppTypography.labelStrong,
              ),
            ),
            TextButton(
              onPressed: onExact,
              child: Text(
                AppStrings.DATETIME_SHEET_CHANGE_TIME,
                style: AppTypography.label.copyWith(color: AppColors.PRIMARY),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.SM8),
        Row(
          children: [
            for (final (String label, int hour) in [
              (AppStrings.DATETIME_SHEET_MORNING, 9),
              (AppStrings.DATETIME_SHEET_NOON, 12),
              (AppStrings.DATETIME_SHEET_EVENING, 16),
            ])
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.SM8),
                child: _Pill(
                  label: label,
                  isSelected: isAt(hour),
                  onTap: () => onPreset(hour, 0),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final String label;
  final VoidCallback onConfirm;

  const _Footer({required this.label, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.BORDER)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Material(
            color: AppColors.PRIMARY,
            borderRadius: BorderRadius.circular(AppRadius.LG),
            child: InkWell(
              onTap: onConfirm,
              borderRadius: BorderRadius.circular(AppRadius.LG),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.LG24,
                  vertical: AppSpacing.SMD12,
                ),
                child: Text(
                  AppStrings.DATETIME_SHEET_CONFIRM,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
