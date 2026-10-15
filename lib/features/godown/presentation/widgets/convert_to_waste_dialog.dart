import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';

/// Confirms writing a rejected lot off as waste, with an optional reason.
/// Left blank, the server fills in its own default naming the lot and
/// farmer -- mirrors [ConfirmationDialog]'s shell with one extra field.
class ConvertToWasteDialog extends StatefulWidget {
  final String title;
  final String body;
  final String confirmLabel;

  const ConvertToWasteDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  /// Resolves to `null` if cancelled, or the typed reason (possibly empty)
  /// if confirmed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (_) => ConvertToWasteDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<ConvertToWasteDialog> createState() => _ConvertToWasteDialogState();
}

class _ConvertToWasteDialogState extends State<ConvertToWasteDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
            Text(widget.title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.SM8),
            Text(
              widget.body,
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.MD16),
            AppTextField(
              controller: _reasonController,
              label: AppStrings.WASTE_FIELD_REASON,
              hint: AppStrings.INWARD_CONVERT_TO_WASTE_REASON_HINT,
              inputFormatters: [LengthLimitingTextInputFormatter(255)],
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.LG24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: () =>
                      Navigator.of(context).pop(_reasonController.text.trim()),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.WARNING,
                  ),
                  child: Text(
                    widget.confirmLabel,
                    style: AppTypography.button.copyWith(
                      color: AppColors.WARNING,
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
