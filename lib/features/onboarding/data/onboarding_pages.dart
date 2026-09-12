import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String body;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class OnboardingPages {
  OnboardingPages._();

  static const List<OnboardingPage> all = [
    OnboardingPage(
      icon: Icons.eco_outlined,
      title: AppStrings.ONBOARDING_TITLE_1,
      body: AppStrings.ONBOARDING_BODY_1,
    ),
    OnboardingPage(
      icon: Icons.inventory_2_outlined,
      title: AppStrings.ONBOARDING_TITLE_2,
      body: AppStrings.ONBOARDING_BODY_2,
    ),
    OnboardingPage(
      icon: Icons.receipt_long_outlined,
      title: AppStrings.ONBOARDING_TITLE_3,
      body: AppStrings.ONBOARDING_BODY_3,
    ),
  ];
}
