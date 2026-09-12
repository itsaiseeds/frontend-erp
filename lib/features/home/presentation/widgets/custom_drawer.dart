import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/drawer_items.dart';

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * AppSizes.DRAWER_WIDTH_FACTOR,
      decoration: const BoxDecoration(
        color: AppColors.DRAWER_BG,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.DRAWER),
          bottomRight: Radius.circular(AppRadius.DRAWER),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.LG24),
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  AppAssets.LOGO,
                  height: AppSizes.DRAWER_LOGO_HEIGHT,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.LG24),
              child: Divider(color: AppColors.BORDER),
            ),
            const SizedBox(height: AppSpacing.MD16),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.MD16,
                ),
                children: [
                  for (final item in DrawerItems.primary)
                    _buildDrawerItem(
                      index: item.index,
                      icon: item.icon,
                      title: item.title,
                    ),
                  const SizedBox(height: AppSpacing.LG24),

                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.MD16,
                      bottom: AppSpacing.SMD12,
                    ),
                    child: Text(
                      AppStrings.DRAWER_SECTION_ACCOUNT,
                      style: AppTypography.drawerSectionHeader,
                    ),
                  ),
                  for (final item in DrawerItems.account)
                    _buildDrawerItem(
                      index: item.index,
                      icon: item.icon,
                      title: item.title,
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.LG24),
              child: GestureDetector(
                onTap: onLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.SMD12,
                    horizontal: AppSpacing.MD16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.DRAWER_LOGOUT_BG,
                    borderRadius: BorderRadius.circular(
                      AppSizes.DRAWER_ITEM_RADIUS,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.ERROR,
                        size: AppSizes.DRAWER_LOGOUT_ICON,
                      ),
                      const SizedBox(width: AppSpacing.SMD12),
                      Text(
                        AppStrings.LOGOUT,
                        style: AppTypography.drawerLogout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        onItemSelected(index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.SM8),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.SMD12,
          horizontal: AppSpacing.MD16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.DRAWER_ITEM_ACTIVE_BG
              : AppColors.TRANSPARENT,
          borderRadius: BorderRadius.circular(AppSizes.DRAWER_ITEM_RADIUS),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppSizes.DRAWER_ITEM_ICON,
              color: isSelected
                  ? AppColors.PRIMARY
                  : AppColors.DRAWER_ICON_IDLE,
            ),
            const SizedBox(width: AppSpacing.MD16),
            Text(
              title,
              style: isSelected
                  ? AppTypography.drawerItemActive
                  : AppTypography.drawerItem,
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: AppSizes.DRAWER_ACTIVE_DOT,
                height: AppSizes.DRAWER_ACTIVE_DOT,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.PRIMARY,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
