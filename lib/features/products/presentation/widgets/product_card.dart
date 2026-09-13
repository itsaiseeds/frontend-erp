import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_url_resolver.dart';
import '../../data/models/product_packaging.dart';
import 'quantity_stepper.dart';
import 'stage_palette.dart';

class ProductCard extends StatelessWidget {
  final ProductPackaging packaging;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductCard({
    super.key,
    required this.packaging,
    required this.quantity,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.XS5),
        decoration: BoxDecoration(
          color: AppColors.SURFACE,
          border: Border.all(color: AppColors.BORDER),
          borderRadius: BorderRadius.circular(AppRadius.XL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePanel(),
            const SizedBox(height: AppSpacing.SM8),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  /// The stepper straddles the bottom edge of the tinted box. The panel is
  /// taller than the box by that overlap so the button stays inside the
  /// Stack -- anything outside it would be unclickable, not just clipped.
  Widget _buildImagePanel() {
    return SizedBox(
      height:
          AppSizes.PRODUCT_CARD_IMAGE + AppSizes.PRODUCT_CARD_STEPPER_OVERLAP,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: AppSizes.PRODUCT_CARD_IMAGE,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.SURFACE_VARIANT,
                borderRadius: BorderRadius.circular(AppRadius.LG),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(AppSpacing.SM8),
              child: _buildImage(),
            ),
          ),
          if (packaging.totalWeightSummary.isNotEmpty)
            Positioned(
              left: AppSpacing.SM8,
              top:
                  AppSizes.PRODUCT_CARD_IMAGE - AppSizes.PRODUCT_CARD_TAG_INSET,
              child: _Tag(
                label: packaging.totalWeightSummary,
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: AppSizes.PRODUCT_CARD_STEPPER_WIDTH,
              child: QuantityStepper(
                quantity: quantity,
                onAdd: onAdd,
                onRemove: onRemove,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final String url = ImageUrlResolver.resolve(packaging.imageUrl);

    return url.isEmpty
        ? const Center(child: _ImageFallback())
        : Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (context, error, stack) =>
                const Center(child: _ImageFallback()),
          );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                packaging.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.TEXT_PRIMARY,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (packaging.stageName.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.XS6),
              _StageBadge(
                label: packaging.stageName,
                sequence: packaging.stageSequence,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.XXS2),
        Text(
          CurrencyFormatter.rupees(packaging.sellingPrice),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.TEXT_PRIMARY,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (packaging.packetSummary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.XS6),
          _PacketPill(label: packaging.packetSummary),
        ],
      ],
    );
  }
}

class _PacketPill extends StatelessWidget {
  final String label;

  const _PacketPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.XS6,
          vertical: AppSpacing.XXS2,
        ),
        decoration: BoxDecoration(
          color: AppColors.SURFACE_VARIANT,
          borderRadius: BorderRadius.circular(AppRadius.SM),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.TEXT_SECONDARY,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String label;
  final int sequence;

  const _StageBadge({required this.label, required this.sequence});

  @override
  Widget build(BuildContext context) {
    final StageColors colors = StagePalette.forSequence(sequence);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.XS6,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.XS),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.overline.copyWith(color: colors.foreground),
      ),
    );
  }
}

/// A compact chip: the stage sits above the product shot, the bag weight is
/// laid over it -- the way a grocery card labels pack size.
class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.XS6,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.inventory_2_outlined,
      size: AppSizes.ICON_XXL,
      color: AppColors.TEXT_DISABLED,
    );
  }
}
