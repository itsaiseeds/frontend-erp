import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.MD,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.SHIMMER_BASE,
      highlightColor: AppColors.SHIMMER_HIGHLIGHT,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.SHIMMER_BASE,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ShimmerLines extends StatelessWidget {
  final int lines;
  final double height;
  final double spacing;

  const ShimmerLines({
    super.key,
    this.lines = 3,
    this.height = AppSpacing.SMD12,
    this.spacing = AppSpacing.SM8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.SHIMMER_BASE,
      highlightColor: AppColors.SHIMMER_HIGHLIGHT,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(lines, (index) {
          final bool isLast = index == lines - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: isLast ? 0.6 : 1.0,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.SHIMMER_BASE,
                  borderRadius: BorderRadius.circular(AppRadius.SM),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
