import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class HomePlaceholderView extends StatelessWidget {
  final String title;
  final String body;

  const HomePlaceholderView({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.HOME_PLACEHOLDER_MAX_WIDTH,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.HOME_PLACEHOLDER_ICON,
                height: AppSizes.HOME_PLACEHOLDER_ICON,
                decoration: const BoxDecoration(
                  color: AppColors.PRIMARY_SURFACE,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  size: AppSizes.ICON_XXL,
                  color: AppColors.PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.LG24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: AppSpacing.SM8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
