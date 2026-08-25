import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Application theme configuration.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: AppColors.BACKGROUND,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.PRIMARY,
        onPrimary: AppColors.WHITE,
        secondary: AppColors.PRIMARY_DARK,
        onSecondary: AppColors.WHITE,
        error: AppColors.ERROR,
        onError: AppColors.WHITE,
        surface: AppColors.SURFACE,
        onSurface: AppColors.TEXT_PRIMARY,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.DISPLAY_LARGE,
        displayMedium: AppTextStyles.DISPLAY_MEDIUM,
        headlineLarge: AppTextStyles.H1,
        headlineMedium: AppTextStyles.H2,
        headlineSmall: AppTextStyles.H3,
        titleLarge: AppTextStyles.H4,
        bodyLarge: AppTextStyles.BODY_LARGE,
        bodyMedium: AppTextStyles.BODY_MEDIUM,
        bodySmall: AppTextStyles.BODY_SMALL,
        labelLarge: AppTextStyles.LABEL_LARGE,
        labelMedium: AppTextStyles.LABEL_MEDIUM,
        labelSmall: AppTextStyles.LABEL_SMALL,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.SURFACE,
        foregroundColor: AppColors.TEXT_PRIMARY,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.H3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PRIMARY,
          foregroundColor: AppColors.TEXT_ON_PRIMARY,
          minimumSize: const Size(120, 44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTextStyles.BUTTON_MEDIUM,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.PRIMARY,
          minimumSize: const Size(120, 44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppColors.BORDER),
          textStyle: AppTextStyles.BUTTON_MEDIUM,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.PRIMARY,
          textStyle: AppTextStyles.BUTTON_MEDIUM,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.SURFACE,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.BORDER),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.BORDER, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.BORDER_FOCUSED,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ERROR, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ERROR, width: 1.5),
        ),
        hintStyle: AppTextStyles.BODY_MEDIUM,
        labelStyle: AppTextStyles.LABEL_LARGE,
        errorStyle: AppTextStyles.BODY_SMALL.copyWith(color: AppColors.ERROR),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.SURFACE,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.BORDER),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.DIVIDER,
        thickness: 1,
        space: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.PRIMARY;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.BORDER, width: 1.5),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.DIVIDER),
        radius: const Radius.circular(4),
      ),
    );
  }
}
