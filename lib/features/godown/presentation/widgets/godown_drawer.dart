import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../home/data/drawer_items.dart';

/// The godown shell's own item lists, in the shared [DrawerItem] shape so
/// [CustomDrawer] -- the sales-person app's drawer -- can render either role
/// without a second drawer widget to keep visually in sync.
class GodownDrawerItems {
  GodownDrawerItems._();

  static const int RAW_MATERIAL_STOCK = 0;
  static const int OTHER_MATERIAL_STOCK = 1;
  static const int INWARD_RAW_MATERIALS = 2;
  static const int INWARD_OTHER_MATERIALS = 3;
  static const int RECIPES = 4;
  static const int BAG_STOCK = 5;
  static const int PACKET_STOCK = 6;
  static const int PROFILE = 7;

  static const List<DrawerItem> primary = [
    DrawerItem(
      index: RAW_MATERIAL_STOCK,
      icon: Icons.inventory_2_outlined,
      title: AppStrings.DRAWER_RAW_MATERIAL_STOCK,
    ),
    DrawerItem(
      index: OTHER_MATERIAL_STOCK,
      icon: Icons.category_outlined,
      title: AppStrings.DRAWER_OTHER_MATERIAL_STOCK,
    ),
    DrawerItem(
      index: INWARD_RAW_MATERIALS,
      icon: Icons.local_shipping_outlined,
      title: AppStrings.DRAWER_INWARD_RAW_MATERIALS,
    ),
    DrawerItem(
      index: INWARD_OTHER_MATERIALS,
      icon: Icons.move_to_inbox_outlined,
      title: AppStrings.DRAWER_INWARD_OTHER_MATERIALS,
    ),
    DrawerItem(
      index: RECIPES,
      icon: Icons.receipt_long_outlined,
      title: AppStrings.DRAWER_RECIPES,
    ),
    DrawerItem(
      index: BAG_STOCK,
      icon: Icons.inventory_outlined,
      title: AppStrings.DRAWER_BAG_STOCK,
    ),
    DrawerItem(
      index: PACKET_STOCK,
      icon: Icons.scale_outlined,
      title: AppStrings.DRAWER_PACKET_STOCK,
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
