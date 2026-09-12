import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ClientsFilterBar extends StatelessWidget {
  final String? selectedCity;
  final VoidCallback onPickCity;
  final VoidCallback onSearch;
  final bool isLoading;

  const ClientsFilterBar({
    super.key,
    required this.selectedCity,
    required this.onPickCity,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCity = selectedCity != null && selectedCity!.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.SURFACE,
            borderRadius: BorderRadius.circular(AppRadius.LG),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isLoading ? null : onPickCity,
              child: Container(
                height: AppSizes.CLIENT_FILTER_CONTROL,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.SM14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasCity ? AppColors.PRIMARY : AppColors.BORDER,
                    width: hasCity
                        ? AppSizes.BORDER_MEDIUM
                        : AppSizes.BORDER_THIN,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.LG),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city_outlined,
                      size: AppSizes.ICON_MD,
                      color: hasCity
                          ? AppColors.PRIMARY
                          : AppColors.TEXT_SECONDARY,
                    ),
                    const SizedBox(width: AppSpacing.SM8),
                    Expanded(
                      child: Text(
                        hasCity
                            ? selectedCity!
                            : AppStrings.CLIENTS_SELECT_CITY,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hasCity
                            ? AppTypography.labelMedium
                            : AppTypography.bodyMedium.copyWith(
                                color: AppColors.TEXT_DISABLED,
                              ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: AppSizes.ICON_LG,
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Material(
          color: isLoading ? AppColors.SURFACE_VARIANT : AppColors.PRIMARY,
          borderRadius: BorderRadius.circular(AppRadius.LG),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isLoading ? null : onSearch,
            child: Tooltip(
              message: AppStrings.CLIENTS_SEARCH_TOOLTIP,
              child: SizedBox(
                width: AppSizes.CLIENT_SEARCH_BUTTON,
                height: AppSizes.CLIENT_SEARCH_BUTTON,
                child: Icon(
                  Icons.search_rounded,
                  size: AppSizes.ICON_XL,
                  color: isLoading
                      ? AppColors.TEXT_DISABLED
                      : AppColors.TEXT_ON_PRIMARY,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
