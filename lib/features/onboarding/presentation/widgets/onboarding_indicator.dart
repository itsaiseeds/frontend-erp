import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class OnboardingIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == activeIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.XS4),
          child: Container(
            width: isActive
                ? AppSizes.ONBOARDING_INDICATOR_ACTIVE
                : AppSizes.ONBOARDING_INDICATOR,
            height: AppSizes.ONBOARDING_INDICATOR,
            decoration: BoxDecoration(
              color: isActive ? AppColors.PRIMARY : AppColors.BORDER_STRONG,
              borderRadius: BorderRadius.circular(AppRadius.FULL),
            ),
          ),
        );
      }),
    );
  }
}
