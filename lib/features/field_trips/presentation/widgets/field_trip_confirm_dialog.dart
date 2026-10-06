import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Every irreversible step on a trip -- starting it, ending it, deleting it,
/// editing away its approval -- asks the same question in the same shape, so
/// the salesperson learns one dialog rather than four.
class FieldTripConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool isDangerous;

  const FieldTripConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.isDangerous = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool isDangerous = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (_) => FieldTripConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        isDangerous: isDangerous,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = isDangerous ? AppColors.ERROR : AppColors.PRIMARY;

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
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.SM8),
            Text(body, style: AppTypography.bodySmall.copyWith(height: 1.5)),
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
                  style: TextButton.styleFrom(foregroundColor: accent),
                  child: Text(
                    confirmLabel,
                    style: AppTypography.button.copyWith(color: accent),
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
