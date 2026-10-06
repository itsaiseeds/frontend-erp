import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A loading placeholder shaped exactly like [GodownCard] -- icon tile, title
/// line, a dot-marked tag line with a trailing code pill, then a tinted
/// two-stat footer (each stat its own label-over-value pair) -- so nothing
/// resizes or jumps once real rows replace it.
class GodownCardShimmer extends StatelessWidget {
  final int itemCount;

  const GodownCardShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.SHIMMER_BASE,
      highlightColor: AppColors.SHIMMER_HIGHLIGHT,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < itemCount; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.SMD12),
            const _ShimmerCard(),
          ],
        ],
      ),
    );
  }
}

/// One skeleton row, standalone and unanimated -- for the "load more" footer
/// at the end of a paginated list, where wrapping another `Shimmer.fromColors`
/// around a single card still reads as the same shimmering style.
class GodownCardShimmerTile extends StatelessWidget {
  const GodownCardShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.SHIMMER_BASE,
      highlightColor: AppColors.SHIMMER_HIGHLIGHT,
      child: const _ShimmerCard(),
    );
  }
}

/// Loading placeholder shaped like [StockTable] rather than like [GodownCard]:
/// a tinted header row over alternating flat rows, each with a two-line product
/// block on the left and a fixed-width figure on the right. The card skeleton
/// would drop in bordered boxes the real page never draws, so every row visibly
/// reshuffles the moment data arrives.
///
/// The column widths, paddings and row rhythm below are copied from
/// `StockTable` on purpose -- if that table's geometry changes, this has to
/// change with it.
class GodownTableShimmer extends StatelessWidget {
  final int itemCount;

  const GodownTableShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.SHIMMER_BASE,
      highlightColor: AppColors.SHIMMER_HIGHLIGHT,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ShimmerHeaderRow(),
          for (int i = 0; i < itemCount; i++)
            _ShimmerTableRow(isEven: i.isEven),
        ],
      ),
    );
  }
}

class _ShimmerHeaderRow extends StatelessWidget {
  const _ShimmerHeaderRow();

  /// The real header's text line box, measured off [StockTable] so the band is
  /// the same height before and after load.
  static const double _labelLineBox = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.SURFACE_VARIANT,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.MD16,
        vertical: AppSpacing.SMD12,
      ),
      child: SizedBox(
        height: _labelLineBox,
        child: Row(
          children: [
            const _Block(width: 64, height: AppSpacing.SMD12),
            const SizedBox(width: AppSpacing.SMD12),
            const SizedBox(
              width: AppSizes.GODOWN_TABLE_COLUMN_NARROW,
              child: _Block(width: double.infinity, height: AppSpacing.SMD12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerTableRow extends StatelessWidget {
  final bool isEven;

  const _ShimmerTableRow({required this.isEven});

  /// Line boxes copied from the real row's `bodyMedium` title and `bodySmall`
  /// subtitle. Using the same figures is what keeps the row height identical,
  /// so the list does not nudge when the placeholders are swapped for text.
  static const double _titleLineBox = 20;
  static const double _subtitleLineBox = 17;

  @override
  Widget build(BuildContext context) {
    // Widths are expressed as fractions of the screen rather than fixed pixels
    // so the skeleton keeps the real row's proportions on any handset.
    final double width = MediaQuery.of(context).size.width;

    return ColoredBox(
      color: isEven ? AppColors.SURFACE : AppColors.BACKGROUND_TINTED,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.MD16,
          vertical: AppSpacing.SMD12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _titleLineBox,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Block(
                        width: width * 0.38,
                        height: AppSpacing.SM14,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.XXS2),
                  SizedBox(
                    height: _subtitleLineBox,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Block(
                        width: width * 0.22,
                        height: AppSpacing.SMD12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.SMD12),
            const SizedBox(
              width: AppSizes.GODOWN_TABLE_COLUMN_NARROW,
              child: _Block(width: double.infinity, height: AppSpacing.MD16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Block(
                  width: AppSizes.ORDER_ICON_BOX,
                  height: AppSizes.ORDER_ICON_BOX,
                  radius: AppRadius.LG,
                ),
                const SizedBox(width: AppSpacing.SMD12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Block(
                        width: MediaQuery.of(context).size.width * 0.42,
                        height: AppSpacing.MD16,
                      ),
                      const SizedBox(height: AppSpacing.SM8),
                      Row(
                        children: [
                          const _Dot(),
                          const SizedBox(width: AppSpacing.XS6),
                          _Block(
                            width: MediaQuery.of(context).size.width * 0.24,
                            height: AppSpacing.SMD12,
                          ),
                          const Spacer(),
                          const _Block(
                            width: AppSpacing.XXL48,
                            height: AppSpacing.SMD12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.SMD12,
              vertical: AppSpacing.SM8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.BACKGROUND,
              border: Border(top: BorderSide(color: AppColors.BORDER)),
            ),
            child: const Row(
              children: [
                Expanded(child: _StatBlock()),
                SizedBox(width: AppSpacing.SMD12),
                Expanded(child: _StatBlock()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Block(width: AppSizes.CLIENT_STAT_DIVIDER, height: AppSpacing.XS6),
        SizedBox(height: AppSpacing.XS6),
        _Block(width: double.infinity, height: AppSpacing.SM14),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.CLIENT_STATUS_DOT,
      height: AppSizes.CLIENT_STATUS_DOT,
      decoration: const BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Block({
    required this.width,
    required this.height,
    this.radius = AppRadius.SM,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
