import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class FieldGroupLabel extends StatelessWidget {
  final String label;

  const FieldGroupLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.overline.copyWith(
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
        const SizedBox(width: AppSpacing.SMD12),
        const Expanded(
          child: Divider(height: AppSizes.HAIRLINE, color: AppColors.HAIRLINE),
        ),
      ],
    );
  }
}
