import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/clients_state.dart';

class ClientsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ClientSearchScope scope;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<ClientSearchScope> onScopeChanged;
  final VoidCallback onClear;

  const ClientsSearchBar({
    super.key,
    required this.controller,
    required this.scope,
    required this.onChanged,
    required this.onSubmitted,
    required this.onScopeChanged,
    required this.onClear,
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
                  hintText: scope == ClientSearchScope.companyName
                      ? AppStrings.CLIENTS_SEARCH_NAME_HINT
                      : AppStrings.CLIENTS_SEARCH_ADDRESS_HINT,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.TEXT_DISABLED,
                  ),
                  prefixIcon: _ScopeSelector(
                    scope: scope,
                    onChanged: onScopeChanged,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: AppSizes.SEARCH_SCOPE_WIDTH,
                    minHeight: AppSizes.INPUT_HEIGHT,
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

  static OutlineInputBorder _border(
    Color color, {
    double width = AppSizes.BORDER_THIN,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.CHIP),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _SearchButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SearchButton({required this.isEnabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEnabled ? AppColors.PRIMARY : AppColors.SURFACE_VARIANT,
      borderRadius: BorderRadius.circular(AppRadius.CHIP),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        child: Tooltip(
          message: AppStrings.CLIENTS_SEARCH_TOOLTIP,
          child: SizedBox(
            width: AppSizes.CLIENT_FILTER_CONTROL,
            height: AppSizes.CLIENT_FILTER_CONTROL,
            child: Icon(
              Icons.search_rounded,
              size: AppSizes.ICON_LG,
              color: isEnabled
                  ? AppColors.TEXT_ON_PRIMARY
                  : AppColors.TEXT_DISABLED,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  final ClientSearchScope scope;
  final ValueChanged<ClientSearchScope> onChanged;

  const _ScopeSelector({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ClientSearchScope>(
      onSelected: onChanged,
      initialValue: scope,
      tooltip: AppStrings.CLIENTS_SEARCH_SCOPE,
      color: AppColors.SURFACE,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.CHIP),
      ),
      itemBuilder: (context) => [
        _item(
          ClientSearchScope.companyName,
          AppStrings.CLIENTS_SCOPE_NAME,
          Icons.storefront_rounded,
        ),
        _item(
          ClientSearchScope.address,
          AppStrings.CLIENTS_SCOPE_ADDRESS,
          Icons.location_on_outlined,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.SMD12,
          right: AppSpacing.SM8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scope == ClientSearchScope.companyName
                  ? Icons.storefront_rounded
                  : Icons.location_on_outlined,
              size: AppSizes.ICON_MD,
              color: AppColors.PRIMARY,
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: AppSizes.ICON_MD,
              color: AppColors.TEXT_SECONDARY,
            ),
            Container(
              width: AppSizes.BORDER_THIN,
              height: AppSpacing.LGS20,
              color: AppColors.DIVIDER,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ClientSearchScope> _item(
    ClientSearchScope value,
    String label,
    IconData icon,
  ) {
    final bool isSelected = value == scope;

    return PopupMenuItem<ClientSearchScope>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.ICON_MD,
            color: isSelected ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY,
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Text(
            label,
            style: isSelected
                ? AppTypography.labelMedium.copyWith(color: AppColors.PRIMARY)
                : AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
