import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../loaders/dots_loader.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDangerous;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDangerous = false,
    this.icon,
  });

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = isDangerous ? AppColors.ERROR : AppColors.PRIMARY;
    final Color backgroundColor = _isDisabled
        ? baseColor.withValues(alpha: 0.5)
        : baseColor;

    return ElevatedButton(
      onPressed: _isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.TEXT_ON_PRIMARY,
        disabledBackgroundColor: backgroundColor,
        disabledForegroundColor: AppColors.TEXT_ON_PRIMARY,
        elevation: 0,
        shadowColor: AppColors.TRANSPARENT,
        minimumSize: const Size(
          AppSizes.BUTTON_MIN_WIDTH,
          AppSizes.BUTTON_HEIGHT,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.LG24,
          vertical: AppSpacing.SMD12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: AppSpacing.MD16,
              child: DotsLoader(color: AppColors.TEXT_ON_PRIMARY),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSizes.ICON_SM),
                  const SizedBox(width: AppSpacing.SM8),
                ],
                Text(label, style: AppTypography.button),
              ],
            ),
    );
  }
}
