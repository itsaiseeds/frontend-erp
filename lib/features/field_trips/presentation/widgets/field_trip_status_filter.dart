import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/field_trip_status.dart';

/// Five chips in lifecycle order, "All" first. A horizontal rail rather than
/// a segmented control: there are too many to fit the width at a legible
/// size, and the order itself is information.
class FieldTripStatusFilter extends StatelessWidget {
  final FieldTripStatus? selected;
  final ValueChanged<FieldTripStatus?> onChanged;

  const FieldTripStatusFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static Color _accentFor(FieldTripStatus? status) {
    switch (status) {
      case null:
      case FieldTripStatus.inProgress:
        return AppColors.PRIMARY;
      case FieldTripStatus.planned:
        return AppColors.WARNING;
      case FieldTripStatus.approved:
        return AppColors.INFO;
      case FieldTripStatus.completed:
        return AppColors.SUCCESS;
      case FieldTripStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  static String _labelFor(FieldTripStatus? status) => status == null
      ? AppStrings.FIELD_TRIPS_FILTER_ALL
      : FieldTripStatusX.labelOf(status);

  @override
  Widget build(BuildContext context) {
    const List<FieldTripStatus?> options = [null, ...FieldTripStatusX.ORDERED];

    return SizedBox(
      height: AppSizes.CLIENT_FILTER_CHIP_HEIGHT,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
        itemCount: options.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.SM8),
        itemBuilder: (context, index) {
          final FieldTripStatus? option = options[index];

          return _Chip(
            label: _labelFor(option),
            accent: _accentFor(option),
            isSelected: option == selected,
            onTap: () => onChanged(option),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accent : AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.FULL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.SM14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? accent : AppColors.BORDER,
            ),
            borderRadius: BorderRadius.circular(AppRadius.FULL),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
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
