import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// What a chip stands for: a crop the farmer grows, or a product of ours
/// they use. Ours are outlined in the brand green so they read apart at a
/// glance in a mixed row.
enum FarmerChipKind { crop, product }

class FarmerChip extends StatelessWidget {
  final String label;
  final FarmerChipKind kind;

  const FarmerChip({super.key, required this.label, required this.kind});

  @override
  Widget build(BuildContext context) {
    final bool isOurs = kind == FarmerChipKind.product;
    final Color accent = isOurs
        ? AppColors.PRIMARY
        : AppColors.TEXT_SECONDARY;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(
          color: isOurs ? AppColors.PRIMARY : AppColors.BORDER,
        ),
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOurs ? Icons.inventory_2_outlined : Icons.grass_outlined,
            size: AppSizes.CLIENT_CHIP_ICON,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.XS4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
        ],
      ),
    );
  }
}
