import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/field_trip.dart';

/// The four lifecycle stops with the stamps the backend actually recorded.
///
/// Every stop is drawn whether or not it has happened: the empty ones are
/// what tells the salesperson what the trip is still waiting on, which is
/// the question this card exists to answer.
class FieldTripTimeline extends StatelessWidget {
  final FieldTrip trip;

  const FieldTripTimeline({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final List<_Stop> stops = [
      _Stop(
        label: AppStrings.FIELD_TRIP_TIMELINE_PLANNED,
        at: trip.createdAt,
        icon: Icons.edit_calendar_outlined,
      ),
      _Stop(
        label: AppStrings.FIELD_TRIP_TIMELINE_APPROVED,
        at: trip.approvedAt,
        icon: Icons.verified_outlined,
        isReached: trip.isApproved,
      ),
      _Stop(
        label: AppStrings.FIELD_TRIP_TIMELINE_STARTED,
        at: trip.startedAt,
        icon: Icons.directions_walk_rounded,
      ),
      _Stop(
        label: AppStrings.FIELD_TRIP_TIMELINE_ENDED,
        at: trip.endedAt,
        icon: Icons.flag_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        AppSpacing.SM8,
        AppSpacing.MD16,
        AppSpacing.MD16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < stops.length; index++)
            _StopRow(
              stop: stops[index],
              isLast: index == stops.length - 1,
              isNextReached:
                  index < stops.length - 1 && stops[index + 1].isComplete,
            ),
        ],
      ),
    );
  }
}

class _Stop {
  final String label;
  final DateTime? at;
  final IconData icon;

  /// Approval can be recorded without a stamp, so the reached flag is passed
  /// in rather than inferred from the date alone.
  final bool? isReached;

  const _Stop({
    required this.label,
    required this.at,
    required this.icon,
    this.isReached,
  });

  bool get isComplete => isReached ?? at != null;
}

class _StopRow extends StatelessWidget {
  final _Stop stop;
  final bool isLast;
  final bool isNextReached;

  const _StopRow({
    required this.stop,
    required this.isLast,
    required this.isNextReached,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = stop.isComplete;
    final Color accent = isComplete
        ? AppColors.PRIMARY
        : AppColors.BORDER_STRONG;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.FIELD_TRIP_TIMELINE_GUTTER,
            child: Column(
              children: [
                Container(
                  width: AppSizes.FIELD_TRIP_TIMELINE_DOT,
                  height: AppSizes.FIELD_TRIP_TIMELINE_DOT,
                  decoration: BoxDecoration(
                    color: isComplete ? AppColors.PRIMARY : AppColors.SURFACE,
                    border: Border.all(
                      color: accent,
                      width: AppSizes.BORDER_MEDIUM,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: AppSizes.FIELD_TRIP_TIMELINE_RAIL,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.XS4,
                      ),
                      color: isNextReached
                          ? AppColors.PRIMARY
                          : AppColors.BORDER,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSizes.FIELD_TRIP_TIMELINE_SEGMENT,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        stop.icon,
                        size: AppSizes.ICON_SM,
                        color: isComplete
                            ? AppColors.PRIMARY
                            : AppColors.TEXT_DISABLED,
                      ),
                      const SizedBox(width: AppSpacing.XS6),
                      Text(
                        stop.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: isComplete
                              ? AppColors.TEXT_PRIMARY
                              : AppColors.TEXT_DISABLED,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.XXS2),
                  Text(
                    DateFormatter.dayTimeFull(stop.at),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
