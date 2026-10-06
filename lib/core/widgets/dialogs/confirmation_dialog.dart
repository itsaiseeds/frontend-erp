import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// A "are you sure" prompt for any destructive or hard-to-undo action --
/// deleting a record, flipping a status that cannot be reverted. Mirrors
/// [LogoutConfirmationDialog]'s shape so every confirmation in the app reads
/// the same, parameterised by what is actually being confirmed.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.confirmColor = AppColors.PRIMARY,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    Color confirmColor = AppColors.PRIMARY,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (_) => ConfirmationDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      ),
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
                  style: TextButton.styleFrom(foregroundColor: confirmColor),
                  child: Text(
                    confirmLabel,
                    style: AppTypography.button.copyWith(color: confirmColor),
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
