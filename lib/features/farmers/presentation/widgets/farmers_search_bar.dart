import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A plain search field -- icon, text, a clear button once there's something
/// to clear. No second search button: typing and submitting already trigger
/// a search, so a third control next to the filter button was one too many.
class FarmersSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const FarmersSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final bool hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          style: AppTypography.bodyMedium,
          cursorColor: AppColors.PRIMARY,
          decoration: InputDecoration(
            hintText: AppStrings.FARMERS_SEARCH_HINT,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.TEXT_DISABLED,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: AppSizes.ICON_LG,
              color: AppColors.TEXT_SECONDARY,
            ),
            suffixIcon: hasText
                ? IconButton(
                    onPressed: onClear,
                    tooltip: AppStrings.CLIENTS_CLEAR_SEARCH,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: AppSizes.ICON_MD,
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.SURFACE,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.SMD12,
            ),
            border: _border(AppColors.BORDER),
            enabledBorder: _border(AppColors.BORDER),
            focusedBorder: _border(
              AppColors.BORDER_FOCUSED,
              width: AppSizes.BORDER_MEDIUM,
            ),
          ),
        );
      },
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.LG),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
