import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/bloc/session_cubit.dart';
import '../../clients/presentation/clients_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../data/drawer_items.dart';
import 'widgets/custom_drawer.dart';
import 'widgets/home_placeholder_view.dart';
import 'widgets/logout_confirmation_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _drawerAnimation = Duration(milliseconds: 250);

  late final AnimationController _animationController;
  int _selectedDrawerIndex = DrawerItems.DASHBOARD;

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
    setState(() => _selectedDrawerIndex = index);
    _animationController.reverse();
  }

  Future<void> _handleLogout() async {
    _animationController.reverse();

    final bool confirmed = await LogoutConfirmationDialog.show(context);
    if (!confirmed || !mounted) return;

    await context.read<SessionCubit>().signOut();
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
                        selectedIndex: _selectedDrawerIndex,
                        onItemSelected: _onDrawerItemSelected,
                        onLogout: _handleLogout,
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
      child: Scaffold(
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
            onPressed: _toggleDrawer,
          ),
          title: Text(
            DrawerItems.titleFor(_selectedDrawerIndex),
            style: AppTypography.titleMedium,
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedDrawerIndex == DrawerItems.CLIENTS) {
      return const ClientsScreen();
    }

    if (_selectedDrawerIndex == DrawerItems.PRODUCTS) {
      return const ProductsScreen();
    }

    if (_selectedDrawerIndex == DrawerItems.ORDERS) {
      return const OrdersScreen();
    }

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final String name = state.session?.name ?? '';

        return HomePlaceholderView(
          title:
              _selectedDrawerIndex == DrawerItems.DASHBOARD && name.isNotEmpty
              ? '${AppStrings.HOME_GREETING_PREFIX}, $name'
              : AppStrings.HOME_PLACEHOLDER_TITLE,
          body: AppStrings.HOME_PLACEHOLDER_BODY,
        );
      },
    );
  }
}
