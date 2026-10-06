import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/field_trip.dart';
import 'field_trip_status_badge.dart';

/// One trip at a glance: where it goes and what state it is in, the window it
/// is planned for, then the farmers counted so far in a tinted footer, so the
/// card reads top-down the way an order card does.
class FieldTripCard extends StatelessWidget {
  final FieldTrip trip;
  final VoidCallback? onTap;

  const FieldTripCard({super.key, required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    // The border sits on the clipping shape itself. Drawn on an inner child it
    // would be shaved away at the corners by the antialiased clip.
    return Material(
      color: AppColors.SURFACE,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.PRIMARY_SURFACE,
        highlightColor: AppColors.PRIMARY_SURFACE,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.BORDER_THIN),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.SMD12,
                  AppSpacing.SMD12,
                  AppSpacing.SMD12,
                  AppSpacing.SM8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(trip: trip),
                    const SizedBox(height: AppSpacing.SMD12),
                    _Window(trip: trip),
                  ],
                ),
              ),
              _Footer(trip: trip),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FieldTrip trip;

  const _Header({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.FIELD_TRIP_ICON_BOX,
          height: AppSizes.FIELD_TRIP_ICON_BOX,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_SURFACE,
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: const Icon(
            Icons.map_outlined,
            size: AppSizes.ICON_MD,
            color: AppColors.PRIMARY,
          ),
        ),
        const SizedBox(width: AppSpacing.SMD12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trip.village.trim().isEmpty
                    ? trip.city.name
                    : trip.village,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelStrong.copyWith(
                  color: AppColors.TEXT_PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.XXS2),
              _Location(city: trip.city.name),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.SM8),
        FieldTripStatusBadge(status: trip.status, isCompact: true),
      ],
    );
  }
}

class _Location extends StatelessWidget {
  final String city;

  const _Location({required this.city});

  @override
  Widget build(BuildContext context) {
    if (city.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: AppSizes.ICON_SM,
          color: AppColors.TEXT_SECONDARY,
        ),
        const SizedBox(width: AppSpacing.XXS2),
        Expanded(
          child: Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
      ],
    );
  }
}

/// The planned window as two labelled stops, so a glance answers both "when
/// does it start" and "how long is it" without doing the arithmetic.
class _Window extends StatelessWidget {
  final FieldTrip trip;

  const _Window({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SMD12,
        vertical: AppSpacing.SM8,
      ),
      decoration: BoxDecoration(
        color: AppColors.BACKGROUND_TINTED,
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      // Once a trip has actually run, the plan is history: what the sales
      // person wants to see is when it really started and ended.
      child: Row(
        children: [
          Expanded(
            child: _Stop(
              label: trip.startedAt != null
                  ? AppStrings.FIELD_TRIP_ACTUAL_START
                  : AppStrings.FIELD_TRIP_EXPECTED_START,
              value: DateFormatter.dayTime(
                trip.startedAt ?? trip.expectedStartAt,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            size: AppSizes.ICON_SM,
            color: AppColors.TEXT_DISABLED,
          ),
          Expanded(
            child: _Stop(
              label: trip.endedAt != null
                  ? AppStrings.FIELD_TRIP_ACTUAL_END
                  : AppStrings.FIELD_TRIP_EXPECTED_END,
              value: DateFormatter.dayTime(trip.endedAt ?? trip.expectedEndAt),
              isTrailing: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  final String label;
  final String value;
  final bool isTrailing;

  const _Stop({
    required this.label,
    required this.value,
    this.isTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isTrailing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.TEXT_DISABLED,
          ),
        ),
        const SizedBox(height: AppSpacing.XXS2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: isTrailing ? TextAlign.right : TextAlign.left,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.TEXT_PRIMARY,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final FieldTrip trip;

  const _Footer({required this.trip});

  @override
  Widget build(BuildContext context) {
    final String noun = trip.farmerVisitCount == 1
        ? AppStrings.FIELD_TRIP_FARMER_COUNT_ONE
        : AppStrings.FIELD_TRIP_FARMER_COUNT_MANY;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SMD12,
        vertical: AppSpacing.SM8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.BACKGROUND,
        border: Border(top: BorderSide(color: AppColors.BORDER)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              trip.publicId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SM8),
          const Icon(
            Icons.groups_outlined,
            size: AppSizes.ICON_SM,
            color: AppColors.PRIMARY,
          ),
          const SizedBox(width: AppSpacing.XS6),
          Text(
            '${trip.farmerVisitCount} $noun',
            style: AppTypography.labelSmall.copyWith(color: AppColors.PRIMARY),
          ),
        ],
      ),
    );
  }
}
