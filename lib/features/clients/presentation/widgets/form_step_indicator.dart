import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FormStepIndicator extends StatelessWidget {
  final int stepIndex;
  final int stepCount;
  final String label;
  final String progressText;
  final ValueChanged<int>? onStepTapped;
  final int minStepIndex;

  const FormStepIndicator({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.label,
    required this.progressText,
    this.onStepTapped,
    this.minStepIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.titleMedium)),
            Text(progressText, style: AppTypography.labelSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.SMD12),
        Row(
          children: List.generate(stepCount - minStepIndex, (position) {
            final int index = position + minStepIndex;
            final bool isDone = index <= stepIndex;
            final bool isReachable = index < stepIndex;
            return Expanded(
              child: GestureDetector(
                onTap: isReachable ? () => onStepTapped?.call(index) : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.SM8),
                  child: Container(
                    height: AppSizes.CLIENT_SHEET_HANDLE_HEIGHT,
                    margin: EdgeInsets.only(
                      right: index == stepCount - 1 ? 0 : AppSpacing.XS6,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.PRIMARY
                          : AppColors.SURFACE_VARIANT,
                      borderRadius: BorderRadius.circular(AppRadius.FULL),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
