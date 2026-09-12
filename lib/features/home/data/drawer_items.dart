import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class DrawerItem {
  final int index;
  final IconData icon;
  final String title;

  const DrawerItem({
    required this.index,
    required this.icon,
    required this.title,
  });
}

class DrawerItems {
  DrawerItems._();

  static const int DASHBOARD = 0;
  static const int PRODUCTS = 1;
  static const int ORDERS = 2;
  static const int CLIENTS = 3;
  static const int REPORTS = 4;
  static const int PROFILE = 5;

  static const List<DrawerItem> primary = [
    DrawerItem(
      index: DASHBOARD,
      icon: Icons.dashboard_rounded,
      title: AppStrings.DRAWER_DASHBOARD,
    ),
    DrawerItem(
      index: PRODUCTS,
      icon: Icons.inventory_2_rounded,
      title: AppStrings.DRAWER_PRODUCTS,
    ),
    DrawerItem(
      index: ORDERS,
      icon: Icons.receipt_long_rounded,
      title: AppStrings.DRAWER_ORDERS,
    ),
    DrawerItem(
      index: CLIENTS,
      icon: Icons.storefront_rounded,
      title: AppStrings.DRAWER_CLIENTS,
    ),
    DrawerItem(
      index: REPORTS,
      icon: Icons.analytics_outlined,
      title: AppStrings.DRAWER_REPORTS,
    ),
  ];

  static const List<DrawerItem> account = [
    DrawerItem(
      index: PROFILE,
      icon: Icons.person_outline_rounded,
      title: AppStrings.DRAWER_PROFILE,
    ),
  ];

  static List<DrawerItem> get all => [...primary, ...account];

  static String titleFor(int index) => all
      .firstWhere((item) => item.index == index, orElse: () => primary.first)
      .title;
}
