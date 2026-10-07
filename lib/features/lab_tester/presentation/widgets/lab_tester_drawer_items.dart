import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../home/data/drawer_items.dart';

/// The lab-tester shell's own item lists, in the shared [DrawerItem] shape so
/// [CustomDrawer] can render this role too without a drawer of its own.
class LabTesterDrawerItems {
  LabTesterDrawerItems._();

  static const int PENDING_LOTS = 0;
  static const int LAB_REPORTS = 1;
  static const int PROFILE = 2;

  static const List<DrawerItem> primary = [
    DrawerItem(
      index: PENDING_LOTS,
      icon: Icons.science_outlined,
      title: AppStrings.DRAWER_PENDING_LOTS,
    ),
    DrawerItem(
      index: LAB_REPORTS,
      icon: Icons.fact_check_outlined,
      title: AppStrings.DRAWER_LAB_REPORTS,
    ),
  ];

  static const List<DrawerItem> account = [
    DrawerItem(
      index: PROFILE,
      icon: Icons.person_outline_rounded,
      title: AppStrings.DRAWER_PROFILE,
    ),
  ];
}
