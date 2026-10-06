import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A labelled box that opens something -- a city sheet, a date picker -- and
/// shows what came back. The trip form has three of these, so they share one
/// shell rather than each screen rebuilding the same bordered row.
class FieldTripPickerField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final String? errorText;
  final bool isRequired;
  final VoidCallback onTap;

  const FieldTripPickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTypography.label,
            children: isRequired
                ? [
                    TextSpan(
                      text: AppStrings.REQUIRED_MARKER,
                      style: AppTypography.label.copyWith(
                        color: AppColors.ERROR,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.SM8),
        Material(
          color: AppColors.SURFACE,
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: AppSizes.INPUT_HEIGHT,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError ? AppColors.ERROR : AppColors.BORDER,
                ),
                borderRadius: BorderRadius.circular(AppRadius.CHIP),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppSizes.ICON_MD,
                    color: AppColors.TEXT_SECONDARY,
                  ),
                  const SizedBox(width: AppSpacing.SMD12),
                  Expanded(
                    child: Text(
                      hasValue ? value! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hasValue
                          ? AppTypography.bodyMedium
                          : AppTypography.bodyMedium.copyWith(
                              color: AppColors.TEXT_DISABLED,
                            ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSizes.ICON_LG,
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.XS4),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.ERROR),
          ),
        ],
      ],
    );
  }
}
