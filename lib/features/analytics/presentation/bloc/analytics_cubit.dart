import 'package:equatable/equatable.dart';

import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/analytics_repository.dart';
import '../../data/models/analytics_summary.dart';

enum AnalyticsStatus { initial, loading, loaded, failure }

/// The windows offered on the dashboard. Each is a span of whole days
/// ending today, which is how a salesperson thinks about their own numbers.
enum AnalyticsRange { today, week, month, quarter }

extension AnalyticsRangeX on AnalyticsRange {
  String get label {
    switch (this) {
      case AnalyticsRange.today:
        return AppStrings.ANALYTICS_RANGE_TODAY;
      case AnalyticsRange.week:
        return AppStrings.ANALYTICS_RANGE_WEEK;
      case AnalyticsRange.month:
        return AppStrings.ANALYTICS_RANGE_MONTH;
      case AnalyticsRange.quarter:
        return AppStrings.ANALYTICS_RANGE_QUARTER;
    }
  }

  /// Days the window covers, counting today as one.
  int get days {
    switch (this) {
      case AnalyticsRange.today:
        return 1;
      case AnalyticsRange.week:
        return 7;
      case AnalyticsRange.month:
        return 30;
      case AnalyticsRange.quarter:
        return 90;
    }
  }

  /// Midnight on the first day through to the last moment of today, so a
  /// window never clips orders booked earlier or later in the same day.
  (DateTime, DateTime) boundsFrom(DateTime now) {
    final DateTime endOfToday = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );
    final DateTime startOfFirstDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return (startOfFirstDay, endOfToday);
  }
}

class AnalyticsState extends Equatable {
  final AnalyticsStatus status;
  final AnalyticsSummary? summary;
  final AnalyticsRange range;
  final String? errorMessage;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.summary,
    this.range = AnalyticsRange.month,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    AnalyticsSummary? summary,
    AnalyticsRange? range,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      range: range ?? this.range,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// A reload keeps the previous numbers on screen, so switching window
  /// does not blank the page for the length of a request.
  bool get isRefreshing =>
      status == AnalyticsStatus.loading && summary != null;

  bool get isFirstLoad =>
      status == AnalyticsStatus.loading && summary == null;

  @override
  List<Object?> get props => [status, summary, range, errorMessage];
}

class AnalyticsCubit extends SafeCubit<AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsCubit({required AnalyticsRepository repository})
    : _repository = repository,
      super(const AnalyticsState());

  Future<void> load() => _fetch(state.range);

  Future<void> refresh() => _fetch(state.range);

  Future<void> selectRange(AnalyticsRange range) {
    if (range == state.range && state.summary != null) {
      return Future.value();
    }
    return _fetch(range);
  }

  Future<void> _fetch(AnalyticsRange range) async {
    emit(
      state.copyWith(
        status: AnalyticsStatus.loading,
        range: range,
        clearError: true,
      ),
    );

    final (DateTime start, DateTime end) = range.boundsFrom(DateTime.now());

    try {
      final AnalyticsSummary summary = await _repository.fetchSummary(
        start: start,
        end: end,
      );
      emit(
        state.copyWith(status: AnalyticsStatus.loaded, summary: summary),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: AnalyticsStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AnalyticsStatus.failure,
          errorMessage: AppStrings.ANALYTICS_LOAD_FAILED,
        ),
      );
    }
  }
}
