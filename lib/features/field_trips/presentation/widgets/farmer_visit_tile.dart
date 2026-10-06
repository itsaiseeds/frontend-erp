import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/farmer_visit.dart';
import 'farmer_chip.dart';

/// One farmer as recorded in the field: who they are and how to reach them,
/// their land, and what they grow. Products are only shown when there are
/// any -- a farmer who uses none is the ordinary case, not a gap.
class FarmerVisitTile extends StatelessWidget {
  final FarmerVisit visit;
  final VoidCallback? onTap;

  const FarmerVisitTile({super.key, required this.visit, this.onTap});

  /// Past this the chips wrap onto a third line and the card stops being
  /// scannable, so the rest are counted instead.
  static const int maxChips = 3;

  @override
  Widget build(BuildContext context) {
    final Widget body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.MD16,
        vertical: AppSpacing.SMD12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.FARMER_AVATAR,
                height: AppSizes.FARMER_AVATAR,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.PRIMARY_SURFACE,
                  shape: BoxShape.circle,
                ),
                child: visit.initial.isEmpty
                    ? const Icon(
                        Icons.person_outline_rounded,
                        size: AppSizes.ICON_MD,
                        color: AppColors.PRIMARY,
                      )
                    : Text(
                        visit.initial,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.PRIMARY,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      visit.farmerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.XXS2),
                    _Meta(visit: visit),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.SM8),
              _LandArea(visit: visit),
            ],
          ),
          if (visit.crops.isNotEmpty || visit.products.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.SM8),
            _ChipRow(visit: visit),
          ],
        ],
      ),
    );

    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }
}

/// The crops and products, trimmed to what fits, with the remainder counted.
class _ChipRow extends StatelessWidget {
  final FarmerVisit visit;

  const _ChipRow({required this.visit});

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [
      for (final FarmerCrop crop in visit.crops)
        FarmerChip(label: crop.name, kind: FarmerChipKind.crop),
      for (final FarmerProduct product in visit.products)
        FarmerChip(label: product.name, kind: FarmerChipKind.product),
    ];

    final int hidden = chips.length - FarmerVisitTile.maxChips;

    return Wrap(
      spacing: AppSpacing.XS6,
      runSpacing: AppSpacing.XS6,
      children: [
        ...chips.take(FarmerVisitTile.maxChips),
        if (hidden > 0) _MoreChip(count: hidden),
      ],
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;

  const _MoreChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Text(
        '${AppStrings.ORDER_MORE_PRODUCTS_PREFIX}$count',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.TEXT_SECONDARY,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final FarmerVisit visit;

  const _Meta({required this.visit});

  @override
  Widget build(BuildContext context) {
    final List<String> parts = [
      if (visit.contactNumber.trim().isNotEmpty) visit.contactNumber.trim(),
      if (visit.village.trim().isNotEmpty) visit.village.trim(),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' - '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.TEXT_SECONDARY,
      ),
    );
  }
}

class _LandArea extends StatelessWidget {
  final FarmerVisit visit;

  const _LandArea({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Text(
        '${visit.landAreaLabel} ${AppStrings.FARMER_VISIT_BIGHA}',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.TEXT_PRIMARY,
        ),
      ),
    );
  }
}
