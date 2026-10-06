import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/app_notification.dart';
import '../../data/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsCubit({required NotificationsRepository repository})
    : _repository = repository,
      super(const NotificationsState());

  static const int _pageSize = 20;

  Future<void> load() async {
    emit(
      state.copyWith(status: NotificationsStatus.loading, clearError: true),
    );
    await _fetch(page: 1, replace: true);
  }

  Future<void> refresh() => _fetch(page: 1, replace: true);

  Future<void> loadMore() async {
    final int? next = state.nextPageNumber;
    if (next == null || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    await _fetch(page: next, replace: false);
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    try {
      final PaginatedNotifications result = await _repository
          .fetchNotifications(page: page, pageSize: _pageSize);

      final List<AppNotification> merged = replace
          ? result.results
          : [...state.notifications, ...result.results];

      emit(
        state.copyWith(
          status: NotificationsStatus.loaded,
          notifications: merged,
          page: page,
          totalCount: result.totalCount,
          nextPageNumber: result.nextPageNumber,
          clearNextPage: result.nextPageNumber == null,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: replace ? NotificationsStatus.failure : state.status,
          isLoadingMore: false,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// Marks one row read locally first: the row is already opening, so the
  /// badge must not wait on the network. A failed call leaves the server
  /// out of step until the next refresh, which the inbox corrects.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead || notification.id <= 0) return;

    emit(
      state.copyWith(
        notifications: [
          for (final AppNotification item in state.notifications)
            if (item.id == notification.id) item.copyWith(isRead: true) else item,
        ],
      ),
    );

    try {
      await _repository.markRead(notification.id);
    } on ApiException {
      // Left read locally on purpose: re-marking it unread under the user
      // as they open it would be the more confusing failure.
    }
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;

    final List<AppNotification> previous = state.notifications;
    emit(
      state.copyWith(
        notifications: [
          for (final AppNotification item in previous)
            item.copyWith(isRead: true),
        ],
      ),
    );

    try {
      await _repository.markAllRead();
    } on ApiException catch (error) {
      // Nothing was opened here, so an failure is rolled back rather than
      // leaving the list claiming a state the server does not have.
      emit(
        state.copyWith(notifications: previous, errorMessage: error.message),
      );
    }
  }

  /// Rows bucketed under "Today" / "Yesterday" / a date, in the order the
  /// API sent them -- newest first.
  static List<NotificationGroup> groupByDay(
    List<AppNotification> notifications, {
    DateTime? now,
  }) {
    final List<NotificationGroup> groups = [];
    final Map<String, List<AppNotification>> byHeading = {};

    for (final AppNotification item in notifications) {
      final DateTime? created = item.createdAtDateTime;
      // A row the backend sent without a usable stamp still has to appear,
      // so it joins the newest group rather than being dropped.
      final String heading = created == null
          ? (groups.isEmpty ? '' : groups.last.heading)
          : DateFormatter.relativeDayHeading(created, now: now);

      if (!byHeading.containsKey(heading)) {
        byHeading[heading] = [];
        groups.add(NotificationGroup(heading: heading, items: const []));
      }
      byHeading[heading]!.add(item);
    }

    return [
      for (final NotificationGroup group in groups)
        NotificationGroup(
          heading: group.heading,
          items: byHeading[group.heading]!,
        ),
    ];
  }
}
