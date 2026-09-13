import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ProductsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  /// Defaults to the catalogue hint; other lists reusing this bar pass their
  /// own wording.
  final String hintText;

  const ProductsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.hintText = AppStrings.PRODUCTS_SEARCH_HINT,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final bool hasText = value.text.trim().isNotEmpty;

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMedium,
                cursorColor: AppColors.PRIMARY,
                decoration: InputDecoration(
                  hintText: hintText,
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
              ),
            ),
            const SizedBox(width: AppSpacing.SM8),
            _SearchButton(
              isEnabled: hasText,
              onPressed: () => onSubmitted(controller.text),
            ),
          ],
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

class _SearchButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SearchButton({required this.isEnabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEnabled ? AppColors.PRIMARY : AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          height: AppSizes.CLIENT_FILTER_CONTROL,
          width: AppSizes.CLIENT_FILTER_CONTROL,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? AppColors.PRIMARY : AppColors.BORDER,
            ),
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: Icon(
            Icons.search_rounded,
            size: AppSizes.ICON_MD,
            color: isEnabled
                ? AppColors.TEXT_ON_PRIMARY
                : AppColors.TEXT_SECONDARY,
          ),
        ),
      ),
    );
  }
}
