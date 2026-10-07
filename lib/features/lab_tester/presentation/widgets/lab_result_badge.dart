import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The verdict dot-pill a report card carries: Pass reads green, Fail red,
/// and a record whose result was cleared (a lot sent back for a re-test)
/// reads pending.
///
/// Mirrors the shape of `InwardRawStatusBadge` so the badges that sit on the
/// same screens read as one system.
class LabResultBadge extends StatelessWidget {
  final String? result;
  final bool isCompact;

  const LabResultBadge({super.key, this.result, this.isCompact = false});

  Color get _foreground {
    if (result == 'Pass') return AppColors.SUCCESS;
    if (result == 'Fail') return AppColors.ERROR;
    return AppColors.WARNING;
  }

  Color get _background {
    if (result == 'Pass') return AppColors.SUCCESS_LIGHT;
    if (result == 'Fail') return AppColors.ERROR_LIGHT;
    return AppColors.WARNING_LIGHT;
  }

  String get _label {
    if (result == 'Pass') return AppStrings.LAB_TEST_PASS;
    if (result == 'Fail') return AppStrings.LAB_TEST_FAIL;
    return AppStrings.CLIENT_STATUS_PENDING;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.XS6 : AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.FULL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.CLIENT_STATUS_DOT,
            height: AppSizes.CLIENT_STATUS_DOT,
            decoration: BoxDecoration(
              color: _foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.XS6),
          Text(
            _label,
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}