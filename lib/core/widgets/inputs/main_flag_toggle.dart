import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class MainFlagToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final String label;
  final String hint;
  final ValueChanged<bool> onChanged;

  const MainFlagToggle({
    super.key,
    required this.value,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.TRANSPARENT,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(AppRadius.LG),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.SMD12),
          decoration: BoxDecoration(
            color: value ? AppColors.PRIMARY_SURFACE : AppColors.SURFACE,
            border: Border.all(
              color: value ? AppColors.PRIMARY : AppColors.BORDER,
              width: value ? AppSizes.BORDER_MEDIUM : AppSizes.BORDER_THIN,
            ),
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: Row(
            children: [
              Icon(
                value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: AppSizes.ICON_LG,
                color: value ? AppColors.PRIMARY : AppColors.TEXT_DISABLED,
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color: value
                            ? AppColors.PRIMARY
                            : AppColors.TEXT_PRIMARY,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.XXS2),
                    Text(hint, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
