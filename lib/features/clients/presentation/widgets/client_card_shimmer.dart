import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ClientCardShimmer extends StatelessWidget {
  final int itemCount;
  final bool isScrollable;

  const ClientCardShimmer({
    super.key,
    this.itemCount = 4,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget cards = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < itemCount; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.SMD12),
          const _ShimmerCard(),
        ],
      ],
    );

    final Widget shimmer = Shimmer.fromColors(
      baseColor: AppColors.SHIMMER_BASE,
      highlightColor: AppColors.SHIMMER_HIGHLIGHT,
      child: cards,
    );

    if (!isScrollable) return shimmer;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSizes.CLIENT_LIST_BOTTOM_INSET),
      child: shimmer,
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Block(
                width: AppSizes.CLIENT_AVATAR,
                height: AppSizes.CLIENT_AVATAR,
                radius: AppRadius.LG,
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Block(
                      width: double.infinity,
                      height: AppSpacing.MD16,
                    ),
                    const SizedBox(height: AppSpacing.SM8),
                    _Block(
                      width: MediaQuery.of(context).size.width / 3,
                      height: AppSpacing.SMD12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.MD16),
          const _Block(width: double.infinity, height: AppSpacing.SMD12),
          const SizedBox(height: AppSpacing.SM8),
          const _Block(width: double.infinity, height: AppSpacing.SMD12),
        ],
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
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
