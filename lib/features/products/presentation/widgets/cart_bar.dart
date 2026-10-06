import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_url_resolver.dart';
import '../../data/models/cart_line.dart';

/// A floating pill that slides up once the cart has something in it.
class CartBar extends StatelessWidget {
  static const Duration _duration = Duration(milliseconds: 220);

  final List<CartLine> lines;
  final int itemCount;
  final num total;
  final VoidCallback onTap;

  /// Inline mode drops the slide-in and the outer padding, for placing the
  /// pill inside a row that is already laid out (the detail screen footer).
  final bool isInline;

  const CartBar({
    super.key,
    required this.lines,
    required this.itemCount,
    required this.total,
    required this.onTap,
    this.isInline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isInline) return _buildPill();

    return AnimatedSlide(
      duration: _duration,
      curve: Curves.easeOutCubic,
      offset: itemCount == 0 ? const Offset(0, 1.4) : Offset.zero,
      child: AnimatedOpacity(
        duration: _duration,
        opacity: itemCount == 0 ? 0 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.MD16,
            0,
            AppSpacing.MD16,
            AppSpacing.MD16,
          ),
          child: Center(child: _buildPill()),
        ),
      ),
    );
  }

  Widget _buildPill() {
    return GestureDetector(
      onTap: itemCount == 0 ? null : onTap,
      child: Container(
        height: AppSizes.CART_BAR_HEIGHT,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.XS6),
        decoration: BoxDecoration(
          color: AppColors.PRIMARY,
          borderRadius: BorderRadius.circular(AppRadius.FULL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lines.isNotEmpty) ...[
              _ThumbnailStack(lines: lines),
              const SizedBox(width: AppSpacing.SMD12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.CART_VIEW,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.TEXT_ON_PRIMARY,
                    ),
                  ),
                  Text(
                    '$_itemLabel  ${CurrencyFormatter.rupees(total)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.TEXT_ON_PRIMARY_MUTED,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.SM8),
            const Icon(
              Icons.chevron_right_rounded,
              size: AppSizes.ICON_LG,
              color: AppColors.TEXT_ON_PRIMARY,
            ),
          ],
        ),
      ),
    );
  }

  String get _itemLabel {
    final String noun = itemCount == 1
        ? AppStrings.CART_ITEM
        : AppStrings.CART_ITEMS;
    return '$itemCount $noun';
  }
}

/// Overlapping product shots, the way a grocery cart bar previews its
/// contents. Capped so a large cart does not crowd out the label.
class _ThumbnailStack extends StatelessWidget {
  static const int _maxThumbnails = 3;

  final List<CartLine> lines;

  const _ThumbnailStack({required this.lines});

  @override
  Widget build(BuildContext context) {
    final List<CartLine> shown = lines.take(_maxThumbnails).toList();
    final double width =
        AppSizes.CART_THUMB + (shown.length - 1) * AppSizes.CART_THUMB_STEP;

    return SizedBox(
      width: width,
      height: AppSizes.CART_THUMB,
      child: Stack(
        children: [
          for (int index = shown.length - 1; index >= 0; index--)
            Positioned(
              left: index * AppSizes.CART_THUMB_STEP,
              child: _Thumbnail(url: shown[index].packaging.imageUrl),
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final String resolved = ImageUrlResolver.resolve(url);

    return Container(
      width: AppSizes.CART_THUMB,
      height: AppSizes.CART_THUMB,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.PRIMARY,
          width: AppSizes.BORDER_MEDIUM,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolved.isEmpty
          ? const Icon(
              Icons.inventory_2_outlined,
              size: AppSizes.ICON_SM,
              color: AppColors.TEXT_DISABLED,
            )
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              width: AppSizes.CART_THUMB,
              height: AppSizes.CART_THUMB,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.inventory_2_outlined,
                size: AppSizes.ICON_SM,
                color: AppColors.TEXT_DISABLED,
              ),
            ),
    );
  }
}
