import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/data/models/android_role.dart';
import '../../data/drawer_items.dart';

String roleDisplayName(AndroidRole role) => switch (role) {
  AndroidRole.salesPerson => AppStrings.SWITCH_ROLE_SALES_PERSON,
  AndroidRole.godownManager => AppStrings.SWITCH_ROLE_GODOWN_MANAGER,
  AndroidRole.labTester => AppStrings.SWITCH_ROLE_LAB_TESTER,
};

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  /// Defaults to the sales-person item lists so every existing call site is
  /// unaffected; the godown and lab-tester shells pass their own lists
  /// through these so every role shares one drawer widget rather than one
  /// drawer each.
  final List<DrawerItem> primaryItems;
  final List<DrawerItem> accountItems;

  /// Shown above Logout, only for a user who holds two or more Android
  /// roles. Tapping it opens a picker over [availableRoles].
  final List<AndroidRole> availableRoles;
  final AndroidRole? activeRole;
  final ValueChanged<AndroidRole>? onRoleSelected;

  const CustomDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    this.primaryItems = DrawerItems.primary,
    this.accountItems = DrawerItems.account,
    this.availableRoles = const [],
    this.activeRole,
    this.onRoleSelected,
  });

  bool get _canSwitchRole =>
      availableRoles.length >= 2 && onRoleSelected != null;

  Future<void> _openRolePicker(BuildContext context) async {
    final AndroidRole? chosen = await showModalBottomSheet<AndroidRole>(
      context: context,
      backgroundColor: AppColors.SURFACE,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.XL)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.LG24,
                  AppSpacing.LG24,
                  AppSpacing.LG24,
                  AppSpacing.SM8,
                ),
                child: Text(AppStrings.SWITCH_ROLE, style: AppTypography.titleMedium),
              ),
              for (final role in availableRoles)
                ListTile(
                  leading: Icon(
                    role == activeRole
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: role == activeRole
                        ? AppColors.PRIMARY
                        : AppColors.DRAWER_ICON_IDLE,
                  ),
                  title: Text(roleDisplayName(role), style: AppTypography.drawerItem),
                  onTap: () => Navigator.of(sheetContext).pop(role),
                ),
              const SizedBox(height: AppSpacing.SM8),
            ],
          ),
        );
      },
    );
    if (chosen != null && chosen != activeRole) {
      onRoleSelected?.call(chosen);
    }
  }

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
                  for (final item in primaryItems)
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
                  for (final item in accountItems)
                    _buildDrawerItem(
                      index: item.index,
                      icon: item.icon,
                      title: item.title,
                    ),
                ],
              ),
            ),

            if (_canSwitchRole)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.LG24,
                  0,
                  AppSpacing.LG24,
                  AppSpacing.SM8,
                ),
                child: Material(
                  color: AppColors.PRIMARY_SURFACE,
                  borderRadius: BorderRadius.circular(AppSizes.DRAWER_ITEM_RADIUS),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openRolePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.SMD12,
                        horizontal: AppSpacing.MD16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            color: AppColors.PRIMARY,
                            size: AppSizes.DRAWER_ITEM_ICON,
                          ),
                          const SizedBox(width: AppSpacing.SMD12),
                          Expanded(
                            child: Text(
                              AppStrings.SWITCH_ROLE,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.drawerItem.copyWith(
                                color: AppColors.PRIMARY,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
