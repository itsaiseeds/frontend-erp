import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: AppColors.BACKGROUND,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.TRANSPARENT,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.PRIMARY,
        onPrimary: AppColors.TEXT_ON_PRIMARY,
        secondary: AppColors.PRIMARY_DARK,
        onSecondary: AppColors.TEXT_ON_PRIMARY,
        error: AppColors.ERROR,
        onError: AppColors.TEXT_ON_PRIMARY,
        surface: AppColors.SURFACE,
        onSurface: AppColors.TEXT_PRIMARY,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.SURFACE,
        foregroundColor: AppColors.TEXT_PRIMARY,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PRIMARY,
          foregroundColor: AppColors.TEXT_ON_PRIMARY,
          minimumSize: const Size(
            AppSizes.BUTTON_MIN_WIDTH,
            AppSizes.BUTTON_HEIGHT,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.LG24,
            vertical: AppSpacing.SMD12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.MD),
          ),
          elevation: 0,
          shadowColor: AppColors.TRANSPARENT,
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.PRIMARY,
          textStyle: AppTypography.button,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.DIVIDER,
        thickness: AppSizes.HAIRLINE,
        space: 0,
      ),
    );
  }
}
