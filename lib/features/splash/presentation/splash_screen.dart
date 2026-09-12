import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/loaders/dots_loader.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.WHITE,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.LOGO,
              height: AppSizes.ONBOARDING_LOGO,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.XL32),
            const DotsLoader(),
          ],
        ),
      ),
    );
  }
}
