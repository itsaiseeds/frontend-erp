import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../field_trips/data/models/farmer_visit.dart';
import '../../../field_trips/presentation/widgets/farmer_chip.dart';

/// One directly-recorded farmer as a premium bordered card -- matching the
/// visual language of [ClientCard]/[GodownCard] rather than a flat list row.
class FarmerCard extends StatelessWidget {
  final FarmerVisit farmer;
  final VoidCallback? onTap;

  const FarmerCard({super.key, required this.farmer, this.onTap});

  static const int maxChips = 3;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.XL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.PRIMARY_SURFACE,
        highlightColor: AppColors.PRIMARY_SURFACE,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.BORDER),
            borderRadius: BorderRadius.circular(AppRadius.XL),
          ),
          padding: const EdgeInsets.all(AppSpacing.MD16),
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
                    child: farmer.initial.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            size: AppSizes.ICON_MD,
                            color: AppColors.PRIMARY,
                          )
                        : Text(
                            farmer.initial,
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                farmer.farmerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium,
                              ),
                            ),
                            if (farmer.isLead) ...[
                              const SizedBox(width: AppSpacing.XS6),
                              const _LeadBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.XXS2),
                        _Meta(farmer: farmer),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.SM8),
                  _LandArea(farmer: farmer),
                ],
              ),
              if (farmer.crops.isNotEmpty || farmer.products.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.SMD12),
                _ChipRow(farmer: farmer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The crops and products, trimmed to what fits, with the remainder counted.
class _ChipRow extends StatelessWidget {
  final FarmerVisit farmer;

  const _ChipRow({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [
      for (final FarmerCrop crop in farmer.crops)
        FarmerChip(label: crop.name, kind: FarmerChipKind.crop),
      for (final FarmerProduct product in farmer.products)
        FarmerChip(label: product.name, kind: FarmerChipKind.product),
    ];

    final int hidden = chips.length - FarmerCard.maxChips;

    return Wrap(
      spacing: AppSpacing.XS6,
      runSpacing: AppSpacing.XS6,
      children: [
        ...chips.take(FarmerCard.maxChips),
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

/// Flags a farmer recorded as a sales lead.
class _LeadBadge extends StatelessWidget {
  const _LeadBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.WARNING_LIGHT,
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Text(
        AppStrings.FARMER_LEAD_BADGE,
        style: AppTypography.labelSmall.copyWith(color: AppColors.WARNING),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final FarmerVisit farmer;

  const _Meta({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final List<String> parts = [
      if (farmer.contactNumber.trim().isNotEmpty) farmer.contactNumber.trim(),
      if (farmer.village.trim().isNotEmpty) farmer.village.trim(),
      if (farmer.district.trim().isNotEmpty) farmer.district.trim(),
      if (farmer.cityName.trim().isNotEmpty) farmer.cityName.trim(),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' - '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodySmall.copyWith(color: AppColors.TEXT_SECONDARY),
    );
  }
}

class _LandArea extends StatelessWidget {
  final FarmerVisit farmer;

  const _LandArea({required this.farmer});

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
        '${farmer.landAreaLabel} ${AppStrings.FARMER_VISIT_BIGHA}',
        style: AppTypography.labelSmall.copyWith(color: AppColors.TEXT_PRIMARY),
      ),
    );
  }
}
