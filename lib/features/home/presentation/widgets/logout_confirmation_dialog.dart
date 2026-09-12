import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (_) => const LogoutConfirmationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.SURFACE,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.LG24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.LOGOUT_CONFIRM_TITLE,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.SM8),
            Text(
              AppStrings.LOGOUT_CONFIRM_BODY,
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.LG24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.TEXT_SECONDARY,
                  ),
                  child: Text(
                    AppStrings.CANCEL,
                    style: AppTypography.button.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.SM8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.ERROR),
                  child: Text(
                    AppStrings.LOGOUT,
                    style: AppTypography.button.copyWith(
                      color: AppColors.ERROR,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
