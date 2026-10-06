import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Icon-only indicator for whether today's count is done. The meaning lives in
/// the tooltip rather than a text pill, which keeps the toolbar row compact on
/// a phone while still explaining itself on tap and to screen readers.
class StockCountStatusIcon extends StatelessWidget {
  final bool isComplete;

  const StockCountStatusIcon({super.key, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    final Color color = isComplete ? AppColors.SUCCESS : AppColors.WARNING;

    return Tooltip(
      message: isComplete
          ? AppStrings.STOCK_COUNT_COMPLETE_TOOLTIP
          : AppStrings.STOCK_COUNT_PENDING_TOOLTIP,
      child: Semantics(
        label: isComplete
            ? AppStrings.STOCK_COUNT_COMPLETE
            : AppStrings.STOCK_COUNT_PENDING,
        child: Container(
          width: AppSizes.STOCK_STATUS_ICON_BOX,
          height: AppSizes.STOCK_STATUS_ICON_BOX,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isComplete
                ? AppColors.SUCCESS_LIGHT
                : AppColors.WARNING_LIGHT,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isComplete ? Icons.check_circle_rounded : Icons.pending_outlined,
            size: AppSizes.ICON_LG,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Filter trigger: a tune icon carrying a count of how many controls are off
/// their default, so a narrowed table is obvious without reading the sheet.
/// Shaped and coloured like the filter buttons on the inward and catalogue
/// lists, so the trigger looks the same wherever it appears in the app.
class StockFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const StockFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeCount > 0;

    return Tooltip(
      message: AppStrings.STOCK_FILTER_TOOLTIP,
      child: Material(
        color: isActive ? AppColors.PRIMARY : AppColors.SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.LG),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: AppSizes.CLIENT_FILTER_CONTROL,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.SMD12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? AppColors.PRIMARY : AppColors.BORDER,
              ),
              borderRadius: BorderRadius.circular(AppRadius.LG),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: AppSizes.ICON_MD,
                  color: isActive
                      ? AppColors.TEXT_ON_PRIMARY
                      : AppColors.TEXT_SECONDARY,
                ),
                if (isActive) ...[
                  const SizedBox(width: AppSpacing.XS6),
                  Text(
                    '$activeCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.TEXT_ON_PRIMARY,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
