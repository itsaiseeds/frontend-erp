import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../auth/presentation/bloc/session_cubit.dart';
import '../data/onboarding_pages.dart';
import 'widgets/onboarding_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Duration _pageAnimation = Duration(milliseconds: 250);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == OnboardingPages.all.length - 1;

  void _onNext() {
    if (_isLastPage) {
      _complete();
      return;
    }
    _pageController.nextPage(duration: _pageAnimation, curve: Curves.easeOut);
  }

  void _complete() {
    context.read<SessionCubit>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.SURFACE,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.LG24,
                AppSpacing.MD16,
                AppSpacing.SM8,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    AppAssets.LOGO,
                    height: AppSizes.ONBOARDING_HEADER_LOGO,
                    fit: BoxFit.contain,
                  ),
                  TextButton(
                    onPressed: _complete,
                    child: Text(
                      AppStrings.ONBOARDING_SKIP,
                      style: AppTypography.button.copyWith(
                        color: AppColors.TEXT_SECONDARY,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: OnboardingPages.all.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = OnboardingPages.all[index];
                  return _OnboardingPageView(page: page);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.LG24),
              child: Column(
                children: [
                  OnboardingIndicator(
                    count: OnboardingPages.all.length,
                    activeIndex: _currentPage,
                  ),
                  const SizedBox(height: AppSpacing.LG24),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: _isLastPage
                          ? AppStrings.ONBOARDING_GET_STARTED
                          : AppStrings.ONBOARDING_NEXT,
                      onPressed: _onNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.LG24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.XL32),
          Container(
            width: AppSizes.ONBOARDING_ILLUSTRATION,
            height: AppSizes.ONBOARDING_ILLUSTRATION,
            decoration: const BoxDecoration(
              color: AppColors.PRIMARY_SURFACE,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: AppSizes.ONBOARDING_ILLUSTRATION_ICON,
              color: AppColors.PRIMARY,
            ),
          ),
          const SizedBox(height: AppSpacing.XXL48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.SMD12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.TEXT_SECONDARY,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.XL32),
        ],
      ),
    );
  }
}
