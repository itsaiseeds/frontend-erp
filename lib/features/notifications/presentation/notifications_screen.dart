import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_repository.dart';
import '../notification_router.dart';
import 'bloc/notifications_cubit.dart';
import 'bloc/notifications_state.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// Returns true when anything was read while the screen was open, so the
  /// caller can refresh its badge.
  static Future<bool?> push(BuildContext context) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsCubit>(
      create: (context) => NotificationsCubit(
        repository: NotificationsRepository(
          apiClient: context.read<ApiClient>(),
        ),
      )..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  static const double _loadMoreThreshold = 320;

  final ScrollController _scrollController = ScrollController();

  /// Whether anything was read here, so the badge behind this screen knows
  /// to refetch rather than refreshing on every close.
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double remaining =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining <= _loadMoreThreshold) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  Future<void> _open(AppNotification notification) async {
    final NotificationsCubit cubit = context.read<NotificationsCubit>();
    if (!notification.isRead) {
      _didChange = true;
      cubit.markRead(notification);
    }

    await NotificationRouter.open(
      context,
      notification: notification,
      apiClient: context.read<ApiClient>(),
    );
  }

  void _markAllRead() {
    _didChange = true;
    context.read<NotificationsCubit>().markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.of(context).pop(_didChange);
          },
          child: Scaffold(
            backgroundColor: AppColors.BACKGROUND,
            appBar: AppBar(
              backgroundColor: AppColors.SURFACE,
              surfaceTintColor: AppColors.TRANSPARENT,
              titleSpacing: 0,
              leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
              leading: IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: AppSizes.ICON_XL,
                  color: AppColors.TEXT_PRIMARY,
                ),
                onPressed: () => Navigator.of(context).pop(_didChange),
              ),
              title: Text(
                AppStrings.NOTIFICATIONS_TITLE,
                style: AppTypography.titleMedium,
              ),
              actions: [
                if (state.unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      AppStrings.NOTIFICATIONS_MARK_ALL_READ,
                      style: AppTypography.label.copyWith(
                        color: AppColors.PRIMARY,
                      ),
                    ),
                  ),
              ],
            ),
            body: _Body(
              state: state,
              scrollController: _scrollController,
              onTapNotification: _open,
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final NotificationsState state;
  final ScrollController scrollController;
  final void Function(AppNotification) onTapNotification;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onTapNotification,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == NotificationsStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.PRIMARY),
      );
    }

    if (state.status == NotificationsStatus.failure &&
        state.notifications.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
        body: '',
        action: TextButton(
          onPressed: () => context.read<NotificationsCubit>().refresh(),
          child: Text(
            AppStrings.NOTIFICATIONS_RETRY,
            style: AppTypography.label.copyWith(color: AppColors.PRIMARY),
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return const _Message(
        icon: Icons.notifications_none_rounded,
        title: AppStrings.NOTIFICATIONS_EMPTY_TITLE,
        body: AppStrings.NOTIFICATIONS_EMPTY_BODY,
      );
    }

    final List<NotificationGroup> groups = NotificationsCubit.groupByDay(
      state.notifications,
    );

    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: () => context.read<NotificationsCubit>().refresh(),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          for (final NotificationGroup group in groups) ...[
            _StickyHeading(heading: group.heading),
            SliverList.builder(
              itemCount: group.items.length,
              itemBuilder: (context, index) {
                final AppNotification item = group.items[index];
                return NotificationTile(
                  notification: item,
                  onTap: () => onTapNotification(item),
                );
              },
            ),
          ],
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.MD16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.PRIMARY),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizes.NOTIFICATION_LIST_BOTTOM_INSET),
          ),
        ],
      ),
    );
  }
}

/// A date heading that stays put while its own rows scroll past it.
class _StickyHeading extends StatelessWidget {
  final String heading;

  const _StickyHeading({required this.heading});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeadingDelegate(heading: heading),
    );
  }
}

class _HeadingDelegate extends SliverPersistentHeaderDelegate {
  final String heading;

  const _HeadingDelegate({required this.heading});

  static const double _height = 36;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
      color: AppColors.BACKGROUND,
      child: Text(
        heading,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.TEXT_SECONDARY,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeadingDelegate oldDelegate) =>
      oldDelegate.heading != heading;
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.XL32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
            const SizedBox(height: AppSpacing.MD16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.SM8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.TEXT_SECONDARY,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.SM8),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
