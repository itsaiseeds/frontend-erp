import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Font size constants.
class AppFontSize {
  AppFontSize._();

  static const double FONT10 = 10.0;
  static const double FONT10_5 = 10.5;
  static const double FONT11 = 11.0;
  static const double FONT12 = 12.0;
  static const double FONT13 = 13.0;
  static const double FONT14 = 14.0;
  static const double FONT15 = 15.0;
  static const double FONT16 = 16.0;
  static const double FONT18 = 18.0;
  static const double FONT20 = 20.0;
  static const double FONT22 = 22.0;
  static const double FONT24 = 24.0;
  static const double FONT28 = 28.0;
  static const double FONT32 = 32.0;
  static const double FONT36 = 36.0;
  static const double FONT40 = 40.0;
}

/// Text style constants.
class AppTextStyles {
  AppTextStyles._();

  // --- Display ---
  static const TextStyle DISPLAY_LARGE = TextStyle(
    fontSize: AppFontSize.FONT40,
    fontWeight: FontWeight.w700,
    color: AppColors.TEXT_PRIMARY,
    letterSpacing: -0.5,
  );

  static const TextStyle DISPLAY_MEDIUM = TextStyle(
    fontSize: AppFontSize.FONT32,
    fontWeight: FontWeight.w700,
    color: AppColors.TEXT_PRIMARY,
    letterSpacing: -0.3,
  );

  // --- Headings ---
  static const TextStyle H1 = TextStyle(
    fontSize: AppFontSize.FONT28,
    fontWeight: FontWeight.w700,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle H2 = TextStyle(
    fontSize: AppFontSize.FONT24,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle H3 = TextStyle(
    fontSize: AppFontSize.FONT20,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_PRIMARY,
  );

  static const TextStyle H4 = TextStyle(
    fontSize: AppFontSize.FONT18,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_PRIMARY,
  );

  // --- Body ---
  static const TextStyle BODY_LARGE = TextStyle(
    fontSize: AppFontSize.FONT16,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_PRIMARY,
    height: 1.6,
  );

  static const TextStyle BODY_MEDIUM = TextStyle(
    fontSize: AppFontSize.FONT14,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_SECONDARY,
    height: 1.5,
  );

  static const TextStyle BODY_SMALL = TextStyle(
    fontSize: AppFontSize.FONT12,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_MUTED,
    height: 1.4,
  );

  // --- Labels ---
  static const TextStyle LABEL_LARGE = TextStyle(
    fontSize: AppFontSize.FONT14,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_PRIMARY,
    letterSpacing: 0.1,
  );

  static const TextStyle LABEL_MEDIUM = TextStyle(
    fontSize: AppFontSize.FONT12,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_SECONDARY,
    letterSpacing: 0.5,
  );

  static const TextStyle LABEL_SMALL = TextStyle(
    fontSize: AppFontSize.FONT11,
    fontWeight: FontWeight.w500,
    color: AppColors.TEXT_MUTED,
    letterSpacing: 0.5,
  );

  // --- Caption / Overline ---
  static const TextStyle CAPTION = TextStyle(
    fontSize: AppFontSize.FONT12,
    fontWeight: FontWeight.w400,
    color: AppColors.TEXT_MUTED,
  );

  static const TextStyle OVERLINE = TextStyle(
    fontSize: AppFontSize.FONT10,
    fontWeight: FontWeight.w600,
    color: AppColors.TEXT_MUTED,
    letterSpacing: 1.5,
  );

  // --- Button ---
  static const TextStyle BUTTON_LARGE = TextStyle(
    fontSize: AppFontSize.FONT16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle BUTTON_MEDIUM = TextStyle(
    fontSize: AppFontSize.FONT14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
