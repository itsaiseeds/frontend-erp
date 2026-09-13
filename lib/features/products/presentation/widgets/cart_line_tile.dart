import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_url_resolver.dart';
import '../../data/models/cart_line.dart';
import 'quantity_stepper.dart';

class CartLineTile extends StatelessWidget {
  final CartLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CartLineTile({
    super.key,
    required this.line,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.MD16,
        vertical: AppSpacing.SMD12,
      ),
      child: Row(
        children: [
          _buildThumbnail(),
          const SizedBox(width: AppSpacing.SMD12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.packaging.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium,
                ),
                const SizedBox(height: AppSpacing.XXS2),
                Text(
                  line.packaging.packetSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
                const SizedBox(height: AppSpacing.XS6),
                Text(
                  CurrencyFormatter.rupees(line.lineTotal),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.PRIMARY,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          SizedBox(
            height: AppSizes.STEPPER_HEIGHT,
            child: QuantityStepper(
              quantity: line.quantity,
              onAdd: onAdd,
              onRemove: onRemove,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final String url = ImageUrlResolver.resolve(line.packaging.imageUrl);

    return Container(
      width: AppSizes.CART_THUMBNAIL,
      height: AppSizes.CART_THUMBNAIL,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(
              Icons.inventory_2_outlined,
              size: AppSizes.ICON_LG,
              color: AppColors.TEXT_DISABLED,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: AppSizes.CART_THUMBNAIL,
              height: AppSizes.CART_THUMBNAIL,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.inventory_2_outlined,
                size: AppSizes.ICON_LG,
                color: AppColors.TEXT_DISABLED,
              ),
            ),
    );
  }
}
