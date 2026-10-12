import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/godown_stock.dart';

/// One product's other-material position: every material type it uses, each
/// on its own row, under one card -- the mobile counterpart of the admin
/// table's "Packaging · Material Type · On Hand" grouping
/// (`?group_by=configuration`), but read as a single product summary instead
/// of a flat row per material type.
class OtherMaterialProductCard extends StatelessWidget {
  final String productName;
  final String packetWeightLabel;
  final List<OtherMaterialStockLine> lines;

  const OtherMaterialProductCard({
    super.key,
    required this.productName,
    required this.packetWeightLabel,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.SMD12,
              AppSpacing.SMD12,
              AppSpacing.SMD12,
              AppSpacing.SM8,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.ORDER_ICON_BOX,
                  height: AppSizes.ORDER_ICON_BOX,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_SURFACE,
                    borderRadius: BorderRadius.circular(AppRadius.LG),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    size: AppSizes.ICON_MD,
                    color: AppColors.PRIMARY,
                  ),
                ),
                const SizedBox(width: AppSpacing.SMD12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelStrong.copyWith(
                          color: AppColors.TEXT_PRIMARY,
                        ),
                      ),
                      if (packetWeightLabel.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.XXS2),
                        Text(
                          packetWeightLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.TEXT_SECONDARY,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.SM8,
                    vertical: AppSpacing.XXS2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.SURFACE_VARIANT,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${lines.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int index = 0; index < lines.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.SMD12),
                child: Divider(
                  height: AppSizes.DIVIDER_THIN,
                  thickness: AppSizes.DIVIDER_THIN,
                  color: AppColors.DIVIDER,
                ),
              ),
            _MaterialTypeRow(line: lines[index]),
          ],
        ],
      ),
    );
  }
}

class _MaterialTypeRow extends StatelessWidget {
  final OtherMaterialStockLine line;

  const _MaterialTypeRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.BACKGROUND,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SMD12,
        vertical: AppSpacing.SM8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.materialType.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.TEXT_TERTIARY,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SM8),
          if (line.isShort) ...[
            const Icon(
              Icons.warning_amber_rounded,
              size: AppSizes.ICON_SM,
              color: AppColors.ERROR,
            ),
            const SizedBox(width: AppSpacing.XXS2),
          ],
          Text(
            '${line.onHand} ${line.materialType.unitType}',
            style: AppTypography.labelMedium.copyWith(
              color: line.isShort ? AppColors.ERROR : AppColors.PRIMARY,
            ),
          ),
        ],
      ),
    );
  }
}
