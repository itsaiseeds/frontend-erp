import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Picks the next status for a lot. With a single allowed option there is
/// nothing to pick between, so it renders as one direct action button; with
/// more than one it becomes a dropdown field so the choice reads as a
/// selection rather than a row of competing buttons.
class StatusDropdown<T> extends StatelessWidget {
  final List<T> options;
  final String Function(T) labelOf;
  final bool isBusy;
  final ValueChanged<T> onSelected;

  const StatusDropdown({
    super.key,
    required this.options,
    required this.labelOf,
    required this.isBusy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    if (options.length == 1) {
      final T only = options.first;
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isBusy ? null : () => onSelected(only),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.PRIMARY,
            foregroundColor: AppColors.TEXT_ON_PRIMARY,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.SMD12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.LG),
            ),
          ),
          child: Text(
            labelOf(only),
            style: AppTypography.button.copyWith(
              color: AppColors.TEXT_ON_PRIMARY,
            ),
          ),
        ),
      );
    }

    return PopupMenuButton<T>(
      enabled: !isBusy,
      onSelected: onSelected,
      tooltip: AppStrings.INWARD_CHANGE_STATUS,
      color: AppColors.SURFACE,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      itemBuilder: (context) => [
        for (final T option in options)
          PopupMenuItem<T>(
            value: option,
            child: Text(labelOf(option), style: AppTypography.bodyMedium),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.MD16,
          vertical: AppSpacing.SMD12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.BORDER),
          borderRadius: BorderRadius.circular(AppRadius.LG),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.INWARD_SELECT_STATUS_HINT,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.TEXT_SECONDARY,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.TEXT_SECONDARY,
            ),
          ],
        ),
      ),
    );
  }
}
