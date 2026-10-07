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
import 'lab_reports_screen.dart';
import 'pending_lots_screen.dart';
import 'widgets/lab_tester_drawer_items.dart';

/// The lab-tester shell. The slide-out drawer, drag gestures and animation
/// are the exact mechanics `HomeScreen` and `GodownHomeScreen` use -- the
/// same widget ([CustomDrawer]), handed this role's own item lists -- so all
/// three shells feel like one app rather than three.
class LabTesterHomeScreen extends StatefulWidget {
  const LabTesterHomeScreen({super.key});

  @override
  State<LabTesterHomeScreen> createState() => _LabTesterHomeScreenState();
}

class _LabTesterHomeScreenState extends State<LabTesterHomeScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _drawerAnimation = Duration(milliseconds: 250);

  late final AnimationController _animationController;
  int _selectedIndex = LabTesterDrawerItems.PENDING_LOTS;

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

  void _onRoleSelected(AndroidRole role) {
    _animationController.reverse();
    context.read<SessionCubit>().switchRole(role);
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
    final List<AndroidRole> availableRoles = context.select<SessionCubit, List<AndroidRole>>(
      (cubit) => cubit.state.availableRoles,
    );
    final AndroidRole? activeRole = context.select<SessionCubit, AndroidRole?>(
      (cubit) => cubit.state.effectiveRole,
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
                        primaryItems: LabTesterDrawerItems.primary,
                        accountItems: LabTesterDrawerItems.account,
                        availableRoles: availableRoles,
                        activeRole: activeRole,
                        onRoleSelected: _onRoleSelected,
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
      case LabTesterDrawerItems.PENDING_LOTS:
        return PendingLotsScreen(onMenuTap: _toggleDrawer);
      case LabTesterDrawerItems.LAB_REPORTS:
        return LabReportsScreen(onMenuTap: _toggleDrawer);
      case LabTesterDrawerItems.PROFILE:
        return _ProfileWithMenu(onMenuTap: _toggleDrawer);
      default:
        return PendingLotsScreen(onMenuTap: _toggleDrawer);
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