import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// The "are you sure" prompt shown before a bag/packet stock count is saved,
/// with a "reuse other material" checkbox: a lower count feeds the removed
/// stock back into the other material pool unless the godown manager
/// explicitly turns this off.
///
/// On by default -- that is the safe outcome for a routine same/higher count
/// submission, where nothing is actually being reused. It only matters, and
/// needs a deliberate uncheck, when a product's count is genuinely going
/// down.
class StockUpdateConfirmDialog extends StatefulWidget {
  final String title;
  final String body;
  final String confirmLabel;

  const StockUpdateConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  /// Resolves to `null` if cancelled, or the chosen "reuse other material"
  /// value if confirmed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (_) => StockUpdateConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<StockUpdateConfirmDialog> createState() =>
      _StockUpdateConfirmDialogState();
}

class _StockUpdateConfirmDialogState extends State<StockUpdateConfirmDialog> {
  bool _reuseOtherMaterial = true;

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
            Container(
              padding: const EdgeInsets.all(AppSpacing.MD16),
              decoration: BoxDecoration(
                color: AppColors.WARNING_LIGHT,
                borderRadius: BorderRadius.circular(AppRadius.MD),
                border: Border.all(color: AppColors.WARNING),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.WARNING,
                  ),
                  const SizedBox(width: AppSpacing.SM8),
                  Expanded(
                    child: Text(
                      AppStrings.STOCK_UPDATE_CONFIRM_DECREASE_HINT,
                      style: AppTypography.bodySmall.copyWith(
                        height: 1.5,
                        color: AppColors.TEXT_PRIMARY,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              value: _reuseOtherMaterial,
              onChanged: (bool? value) =>
                  setState(() => _reuseOtherMaterial = value ?? false),
              title: Text(
                AppStrings.STOCK_REUSE_OTHER_MATERIAL,
                style: AppTypography.bodyMedium,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
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
                      Navigator.of(context).pop(_reuseOtherMaterial),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.PRIMARY,
                  ),
                  child: Text(
                    widget.confirmLabel,
                    style: AppTypography.button.copyWith(
                      color: AppColors.PRIMARY,
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
