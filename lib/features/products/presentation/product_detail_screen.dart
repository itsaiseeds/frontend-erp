import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/image_url_resolver.dart';
import '../data/models/product_packaging.dart';
import 'bloc/products_cubit.dart';
import 'bloc/products_state.dart';
import 'checkout_screen.dart';
import 'widgets/cart_bar.dart';
import 'widgets/quantity_stepper.dart';
import 'widgets/stage_palette.dart';
import 'widgets/image_viewer_sheet.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductPackaging packaging;

  const ProductDetailScreen({super.key, required this.packaging});

  void _openCheckout(BuildContext context) {
    final ProductsCubit cubit = context.read<ProductsCubit>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProductsCubit>.value(
          value: cubit,
          child: const CheckoutScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final ProductsCubit cubit = context.read<ProductsCubit>();
        final int quantity = state.quantityOf(packaging.publicId);

        final Widget actionBar = _ActionBar(
          packaging: packaging,
          quantity: quantity,
          onAdd: () => cubit.addToCart(packaging),
          onRemove: () => cubit.removeFromCart(packaging),
        );

        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          appBar: AppBar(
            backgroundColor: AppColors.SURFACE,
            surfaceTintColor: AppColors.TRANSPARENT,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: AppSizes.ICON_XL,
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
            title: Text(
              AppStrings.PRODUCT_DETAIL_TITLE,
              style: AppTypography.titleMedium,
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.only(
                  bottom: AppSizes.PRODUCT_DETAIL_BOTTOM_INSET,
                ),
                children: [
                  _HeroImage(packaging: packaging),
                  const SizedBox(height: AppSpacing.SMD12),
                  _DetailsCard(packaging: packaging),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floats above the bar, as on the catalogue screen, so it
                    // never competes with the price for the footer row.
                    CartBar(
                      lines: state.cartLines,
                      itemCount: state.cartItemCount,
                      total: state.cartTotal,
                      onTap: () => _openCheckout(context),
                    ),
                    actionBar,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-bleed product shot on a tinted ground, with the stage badge floated
/// over it -- the packet is the first thing the buyer should recognise.
class _HeroImage extends StatelessWidget {
  final ProductPackaging packaging;

  const _HeroImage({required this.packaging});

  @override
  Widget build(BuildContext context) {
    final String url = ImageUrlResolver.resolve(packaging.imageUrl);

    return SizedBox(
      height: AppSizes.PRODUCT_DETAIL_IMAGE,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: url.isEmpty
                  ? null
                  : () => ImageViewerSheet.show(
                      context,
                      imageUrl: packaging.imageUrl,
                      footer: BlocProvider<ProductsCubit>.value(
                        value: context.read<ProductsCubit>(),
                        child: _ViewerFooter(packaging: packaging),
                      ),
                    ),
              child: Container(
                color: AppColors.SURFACE_VARIANT,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.LG24,
                ),
                alignment: Alignment.center,
                child: url.isEmpty
                    ? const _ImageFallback()
                    : Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const _ImageFallback(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One card: a tinted product block on top, the description beneath it on the
/// card's own ground -- so the page reads as a single sheet.
class _DetailsCard extends StatelessWidget {
  final ProductPackaging packaging;

  const _DetailsCard({required this.packaging});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.SMD12),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProductBlock(packaging: packaging),
          if (packaging.descriptionItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.MD16),
              child: _DescriptionSection(items: packaging.descriptionItems),
            ),
        ],
      ),
    );
  }
}

class _ProductBlock extends StatelessWidget {
  final ProductPackaging packaging;

  const _ProductBlock({required this.packaging});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.PRIMARY_SURFACE,
      padding: const EdgeInsets.all(AppSpacing.MD16),
      child: Column(
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
          const SizedBox(height: AppSpacing.SM8),
          Wrap(
            spacing: AppSpacing.XS6,
            runSpacing: AppSpacing.XS6,
            children: [
              if (packaging.packetSummary.isNotEmpty)
                _PacketChip(label: packaging.packetSummary),
              if (packaging.totalWeightSummary.isNotEmpty)
                _PacketChip(
                  label:
                      '${AppStrings.TOTAL_LABEL}: '
                      '${packaging.totalWeightSummary}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.SM8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.rupees(packaging.sellingPrice),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.TEXT_PRIMARY,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.XS6),
              Text(
                AppStrings.PRODUCT_PER_BAG,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.TEXT_SECONDARY,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
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

class _PacketChip extends StatelessWidget {
  final String label;

  const _PacketChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.PRIMARY),
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.PRIMARY,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final List<String> items;

  const _DescriptionSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.PRODUCT_DESCRIPTION,
          style: AppTypography.labelStrong.copyWith(
            color: AppColors.TEXT_PRIMARY,
          ),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.SMD12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.PRODUCT_BULLET,
                  height: AppSizes.PRODUCT_BULLET,
                  margin: const EdgeInsets.only(top: AppSpacing.XS6),
                  decoration: const BoxDecoration(
                    color: AppColors.PRIMARY,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.SMD12),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Rebuilds with the cart, so the stepper in the image viewer tracks taps
/// instead of showing the quantity captured when the viewer opened.
class _ViewerFooter extends StatelessWidget {
  final ProductPackaging packaging;

  const _ViewerFooter({required this.packaging});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final ProductsCubit cubit = context.read<ProductsCubit>();

        return _ActionBar(
          packaging: packaging,
          quantity: state.quantityOf(packaging.publicId),
          onAdd: () => cubit.addToCart(packaging),
          onRemove: () => cubit.removeFromCart(packaging),
        );
      },
    );
  }
}

/// Sticky footer: the pack summary and price sit on the left, the action on
/// the right -- a full-width button wastes the row and buries the price.
class _ActionBar extends StatelessWidget {
  final ProductPackaging packaging;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ActionBar({
    required this.packaging,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.SURFACE,
        border: Border(top: BorderSide(color: AppColors.BORDER)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(AppSpacing.MD16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (packaging.packetSummary.isNotEmpty)
                    Text(
                      packaging.packetSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.TEXT_SECONDARY,
                      ),
                    ),
                  Text(
                    CurrencyFormatter.rupees(packaging.sellingPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.TEXT_PRIMARY,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.MD16),
            SizedBox(
              // The stepper needs far less room than the ADD pill.
              width: quantity > 0
                  ? AppSizes.PRODUCT_DETAIL_STEPPER_WIDTH
                  : AppSizes.PRODUCT_DETAIL_ACTION_WIDTH,
              height: AppSizes.INPUT_HEIGHT,
              child: QuantityStepper(
                quantity: quantity,
                onAdd: onAdd,
                onRemove: onRemove,
                addLabel: AppStrings.PRODUCT_ADD_TO_CART,
                isFilled: true,
              ),
            ),
          ],
        ),
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
