import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/data/models/android_role.dart';
import '../../auth/presentation/bloc/session_cubit.dart';
import '../../home/presentation/widgets/custom_drawer.dart';
import '../../home/presentation/widgets/logout_confirmation_dialog.dart';
import '../../profile/presentation/profile_screen.dart';
import 'bag_stock_screen.dart';
import 'inward_other_list_screen.dart';
import 'inward_raw_list_screen.dart';
import 'other_material_recipes_screen.dart';
import 'other_material_stock_screen.dart';
import 'packet_stock_screen.dart';
import 'raw_material_stock_screen.dart';
import 'widgets/godown_drawer.dart';

/// The godown-manager shell. The slide-out drawer, drag gestures and
/// animation are the exact mechanics `HomeScreen` uses -- the same widget
/// ([CustomDrawer]), handed this role's own item lists -- so the two shells
/// feel like one app rather than two.
class GodownHomeScreen extends StatefulWidget {
  const GodownHomeScreen({super.key});

  @override
  State<GodownHomeScreen> createState() => _GodownHomeScreenState();
}

class _GodownHomeScreenState extends State<GodownHomeScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _drawerAnimation = Duration(milliseconds: 250);

  late final AnimationController _animationController;
  int _selectedIndex = GodownDrawerItems.RAW_MATERIAL_STOCK;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _drawerAnimation,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  void _onDrawerItemSelected(int index) {
    setState(() => _selectedIndex = index);
    _animationController.reverse();
  }

  Future<void> _handleLogout() async {
    _animationController.reverse();

    final bool confirmed = await LogoutConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    await context.read<SessionCubit>().signOut();
  }

  void _switchToSalesPerson() {
    _animationController.reverse();
    context.read<SessionCubit>().switchRole(AndroidRole.salesPerson);
  }

  double get _slideWidth =>
      MediaQuery.of(context).size.width * AppSizes.DRAWER_WIDTH_FACTOR;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _animationController.value += details.primaryDelta! / _slideWidth;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (_animationController.value > AppSizes.DRAWER_TOGGLE_THRESHOLD ||
        velocity > AppSizes.DRAWER_FLING_VELOCITY) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRoleChoice = context.select<SessionCubit, bool>(
      (cubit) => cubit.state.hasRoleChoice,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_animationController.value > 0) _animationController.reverse();
      },
      child: Scaffold(
        backgroundColor: AppColors.SURFACE,
        body: GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final double slideWidth = _slideWidth;
              final double animValue = _animationController.value;
              final double drawerTranslate = (animValue - 1) * slideWidth;
              final double mainTranslate = animValue * slideWidth;

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(drawerTranslate, 0),
                      child: CustomDrawer(
                        selectedIndex: _selectedIndex,
                        onItemSelected: _onDrawerItemSelected,
                        onLogout: _handleLogout,
                        primaryItems: GodownDrawerItems.primary,
                        accountItems: GodownDrawerItems.account,
                        switchRoleLabel: hasRoleChoice
                            ? AppStrings.SWITCH_TO_SALES_PERSON
                            : null,
                        onSwitchRole: hasRoleChoice
                            ? _switchToSalesPerson
                            : null,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(mainTranslate, 0),
                    child: Container(
                      decoration: const BoxDecoration(color: AppColors.SURFACE),
                      child: child,
                    ),
                  ),
                  if (animValue > 0)
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(mainTranslate, 0),
                        child: GestureDetector(
                          onTap: _toggleDrawer,
                          behavior: HitTestBehavior.translucent,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case GodownDrawerItems.RAW_MATERIAL_STOCK:
        return RawMaterialStockScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.OTHER_MATERIAL_STOCK:
        return OtherMaterialStockScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.INWARD_RAW_MATERIALS:
        return InwardRawListScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.INWARD_OTHER_MATERIALS:
        return InwardOtherListScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.RECIPES:
        return OtherMaterialRecipesScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.BAG_STOCK:
        return BagStockScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.PACKET_STOCK:
        return PacketStockScreen(onMenuTap: _toggleDrawer);
      case GodownDrawerItems.PROFILE:
        return _ProfileWithMenu(onMenuTap: _toggleDrawer);
      default:
        return RawMaterialStockScreen(onMenuTap: _toggleDrawer);
    }
  }
}

class _ProfileWithMenu extends StatelessWidget {
  final VoidCallback onMenuTap;

  const _ProfileWithMenu({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.SURFACE,
      appBar: AppBar(
        backgroundColor: AppColors.SURFACE,
        surfaceTintColor: AppColors.TRANSPARENT,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            size: AppSizes.HOME_APP_BAR_ICON,
            color: AppColors.TEXT_PRIMARY,
          ),
          onPressed: onMenuTap,
        ),
        title: Text(
          AppStrings.DRAWER_PROFILE,
          style: AppTypography.titleMedium,
        ),
      ),
      body: const ProfileScreen(),
    );
  }
}
