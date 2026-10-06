import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/data/models/android_role.dart';
import '../../auth/presentation/bloc/session_cubit.dart';
import '../../clients/presentation/clients_screen.dart';
import '../../notifications/data/models/app_notification.dart';
import '../../notifications/notification_router.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import '../../analytics/presentation/analytics_dashboard.dart';
import '../../field_trips/presentation/field_trips_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../return_orders/presentation/return_orders_screen.dart';
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

  StreamSubscription<AppNotification>? _notificationTaps;

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _drawerAnimation,
    );
    _listenForNotificationTaps();
    _refreshUnreadCount();
  }

  /// The badge is a count, not a live list: it is refetched on open, after
  /// the inbox is read, and whenever a push arrives.
  Future<void> _refreshUnreadCount() async {
    try {
      final int count = await NotificationsRepository(
        apiClient: context.read<ApiClient>(),
      ).fetchUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // A badge that cannot be fetched simply stays as it is; nothing here
      // is worth interrupting the user for.
    }
  }

  Future<void> _openNotifications() async {
    _animationController.reverse();
    await NotificationsScreen.push(context);
    if (mounted) await _refreshUnreadCount();
  }

  /// Home is the only screen the router lands on once signed in, so this is
  /// where a notification tap becomes a push. A tap that arrived during a
  /// cold start is waiting in the service and is drained first.
  void _listenForNotificationTaps() {
    _notificationTaps = PushService.instance.onTap.listen(_openNotification);

    final AppNotification? pending = PushService.instance.takePending();
    if (pending == null) return;

    // The first frame has to exist before anything can be pushed onto it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openNotification(pending);
    });
  }

  void _openNotification(AppNotification notification) {
    if (!mounted) return;
    _animationController.reverse();

    NotificationRouter.open(
      context,
      notification: notification,
      apiClient: context.read<ApiClient>(),
    );
    // The tap marks it read server-side, so the badge has to catch up.
    _refreshUnreadCount();
  }

  @override
  void dispose() {
    _notificationTaps?.cancel();
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

  void _switchToGodownManager() {
    _animationController.reverse();
    context.read<SessionCubit>().switchRole(AndroidRole.godownManager);
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
                        selectedIndex: _selectedDrawerIndex,
                        onItemSelected: _onDrawerItemSelected,
                        onLogout: _handleLogout,
                        switchRoleLabel: hasRoleChoice
                            ? AppStrings.SWITCH_TO_GODOWN_MANAGER
                            : null,
                        onSwitchRole: hasRoleChoice ? _switchToGodownManager : null,
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
          actions: [
            NotificationBell(
              unreadCount: _unreadCount,
              onPressed: _openNotifications,
            ),
          ],
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

    if (_selectedDrawerIndex == DrawerItems.RETURN_ORDERS) {
      return const ReturnOrdersScreen();
    }

    if (_selectedDrawerIndex == DrawerItems.FIELD_TRIPS) {
      return const FieldTripsScreen();
    }

    if (_selectedDrawerIndex == DrawerItems.PROFILE) {
      return const ProfileScreen();
    }

    if (_selectedDrawerIndex == DrawerItems.DASHBOARD) {
      return BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) =>
            AnalyticsDashboard(userName: state.session?.name ?? ''),
      );
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
