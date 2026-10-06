import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/keyboard_aware_footer.dart';
import '../data/field_trips_repository.dart';
import '../data/models/farmer_visit.dart';
import '../data/models/field_trip.dart';
import 'bloc/field_trip_detail_cubit.dart';
import 'bloc/field_trip_detail_state.dart';
import 'farmer_visit_form_screen.dart';
import 'field_trip_form_screen.dart';
import 'farmer_detail_screen.dart';
import 'trip_farmers_screen.dart';
import 'widgets/farmer_visit_tile.dart';
import 'widgets/field_trip_confirm_dialog.dart';
import 'widgets/field_trip_status_badge.dart';
import 'widgets/field_trip_timeline.dart';

class FieldTripDetailScreen extends StatelessWidget {
  final FieldTrip trip;

  const FieldTripDetailScreen({super.key, required this.trip});

  /// Returns true when the trip was changed here, so the list refreshes.
  static Future<bool?> push(BuildContext context, {required FieldTrip trip}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FieldTripDetailScreen(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FieldTripDetailCubit>(
      create: (context) => FieldTripDetailCubit(
        repository: FieldTripsRepository(apiClient: context.read<ApiClient>()),
        trip: trip,
      )..load(),
      child: const _FieldTripDetailView(),
    );
  }
}

class _FieldTripDetailView extends StatelessWidget {
  const _FieldTripDetailView();

  Future<void> _edit(BuildContext context, FieldTrip trip) async {
    final FieldTripDetailCubit cubit = context.read<FieldTripDetailCubit>();

    // Editing an approved trip withdraws the approval server-side, so the
    // salesperson agrees to losing it before the form opens.
    if (trip.isApproved) {
      final bool proceed = await FieldTripConfirmDialog.show(
        context,
        title: AppStrings.FIELD_TRIP_REAPPROVAL_TITLE,
        body: AppStrings.FIELD_TRIP_REAPPROVAL_BODY,
        confirmLabel: AppStrings.FIELD_TRIP_REAPPROVAL_CONFIRM,
      );
      if (!proceed || !context.mounted) return;
    }

    final bool? saved = await FieldTripFormScreen.push(context, existing: trip);
    if (saved ?? false) {
      cubit.markChanged();
      await cubit.refresh();
    }
  }

  Future<void> _start(BuildContext context, FieldTrip trip) async {
    final FieldTripDetailCubit cubit = context.read<FieldTripDetailCubit>();

    // Only one trip may be out at a time. The app names the one already
    // running rather than letting the salesperson walk into a 400.
    final FieldTrip? blocking = await cubit.findBlockingRunningTrip();
    if (!context.mounted) return;

    if (blocking != null) {
      ToastUtils.showWarning(
        context,
        AppStrings.FIELD_TRIP_ALREADY_RUNNING_TITLE,
        description: '${AppStrings.FIELD_TRIP_ALREADY_RUNNING_BODY} '
            '${blocking.destination}',
      );
      return;
    }

    final bool confirmed = await FieldTripConfirmDialog.show(
      context,
      title: AppStrings.FIELD_TRIP_START_TITLE,
      body: AppStrings.FIELD_TRIP_START_BODY,
      confirmLabel: AppStrings.FIELD_TRIP_START_CONFIRM,
    );
    if (confirmed) await cubit.start();
  }

  Future<void> _end(BuildContext context) async {
    final FieldTripDetailCubit cubit = context.read<FieldTripDetailCubit>();

    final bool confirmed = await FieldTripConfirmDialog.show(
      context,
      title: AppStrings.FIELD_TRIP_END_TITLE,
      body: AppStrings.FIELD_TRIP_END_BODY,
      confirmLabel: AppStrings.FIELD_TRIP_END_CONFIRM,
    );
    if (confirmed) await cubit.end();
  }

  Future<void> _delete(BuildContext context) async {
    final FieldTripDetailCubit cubit = context.read<FieldTripDetailCubit>();

    final bool confirmed = await FieldTripConfirmDialog.show(
      context,
      title: AppStrings.FIELD_TRIP_DELETE_TITLE,
      body: AppStrings.FIELD_TRIP_DELETE_BODY,
      confirmLabel: AppStrings.FIELD_TRIP_DELETE_CONFIRM,
      isDangerous: true,
    );
    if (confirmed) await cubit.delete();
  }

  Future<void> _recordFarmer(BuildContext context, FieldTrip trip) async {
    final FieldTripDetailCubit cubit = context.read<FieldTripDetailCubit>();

    final bool? saved = await FarmerVisitFormScreen.push(context, trip: trip);
    if (saved ?? false) {
      cubit.markChanged();
      await cubit.refresh();
    }
  }

  void _onStateChanged(BuildContext context, FieldTripDetailState state) {
    final String? error = state.errorMessage;
    if (error != null) {
      ToastUtils.showError(context, error);
      context.read<FieldTripDetailCubit>().acknowledgeError();
      return;
    }

    switch (state.completedAction) {
      case FieldTripAction.none:
        return;
      case FieldTripAction.started:
        ToastUtils.showSuccess(context, AppStrings.FIELD_TRIP_STARTED);
      case FieldTripAction.ended:
        ToastUtils.showSuccess(context, AppStrings.FIELD_TRIP_ENDED);
      case FieldTripAction.deleted:
        ToastUtils.showSuccess(context, AppStrings.FIELD_TRIP_DELETED);
        Navigator.of(context).pop(true);
        return;
    }
    context.read<FieldTripDetailCubit>().acknowledgeAction();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FieldTripDetailCubit, FieldTripDetailState>(
      listenWhen: (previous, current) =>
          previous.completedAction != current.completedAction ||
          previous.errorMessage != current.errorMessage,
      listener: _onStateChanged,
      builder: (context, state) {
        final FieldTrip trip = state.trip;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            Navigator.of(context).pop(state.didChange);
          },
          child: Scaffold(
            backgroundColor: AppColors.BACKGROUND,
            appBar: AppBar(
              backgroundColor: AppColors.SURFACE,
              surfaceTintColor: AppColors.TRANSPARENT,
              elevation: 0,
              titleSpacing: 0,
              leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(state.didChange),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: AppSizes.ICON_XL,
                  color: AppColors.TEXT_PRIMARY,
                ),
              ),
              title: Text(
                AppStrings.FIELD_TRIP_DETAIL_TITLE,
                style: AppTypography.titleMedium,
              ),
              actions: [
                if (trip.canEdit)
                  IconButton(
                    tooltip: AppStrings.FIELD_TRIP_EDIT,
                    onPressed: state.isActing
                        ? null
                        : () => _edit(context, trip),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: AppSizes.ICON_LG,
                      color: AppColors.TEXT_PRIMARY,
                    ),
                  ),
                if (trip.canDelete)
                  IconButton(
                    tooltip: AppStrings.FIELD_TRIP_DELETE,
                    onPressed: state.isActing ? null : () => _delete(context),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: AppSizes.ICON_LG,
                      color: AppColors.ERROR,
                    ),
                  ),
                const SizedBox(width: AppSpacing.XS4),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.PRIMARY,
              onRefresh: context.read<FieldTripDetailCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.SMD12,
                  AppSpacing.SMD12,
                  AppSpacing.SMD12,
                  AppSizes.ORDER_LIST_BOTTOM_INSET,
                ),
                children: [
                  _HeaderCard(trip: trip),
                  const SizedBox(height: AppSpacing.SMD12),
                  if (trip.isAwaitingApproval) ...[
                    const _AwaitingApprovalNotice(),
                    const SizedBox(height: AppSpacing.SMD12),
                  ],
                  _PlanCard(trip: trip),
                  const SizedBox(height: AppSpacing.SMD12),
                  _TimelineCard(trip: trip),
                  const SizedBox(height: AppSpacing.SMD12),
                  _PeopleCard(trip: trip),
                  const SizedBox(height: AppSpacing.SMD12),
                  _FarmersCard(state: state),
                ],
              ),
            ),
            bottomNavigationBar: _PrimaryAction(
              state: state,
              onStart: () => _start(context, trip),
              onEnd: () => _end(context),
              onRecordFarmer: () => _recordFarmer(context, trip),
            ),
          ),
        );
      },
    );
  }
}

/// Where the trip goes and what state it is in, then the farmer count, on a
/// tinted panel -- the same header shape an order detail opens with.
class _HeaderCard extends StatelessWidget {
  final FieldTrip trip;

  const _HeaderCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final String noun = trip.farmerVisitCount == 1
        ? AppStrings.FIELD_TRIP_FARMER_COUNT_ONE
        : AppStrings.FIELD_TRIP_FARMER_COUNT_MANY;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            color: AppColors.PRIMARY_SURFACE,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        trip.destination,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.TEXT_PRIMARY,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.SM8),
                    FieldTripStatusBadge(status: trip.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.XS6),
                Text(
                  trip.publicId,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: noun,
                    value: '${trip.farmerVisitCount}',
                    isEmphasised: true,
                  ),
                ),
                Container(
                  width: AppSizes.BORDER_THIN,
                  height: AppSizes.CLIENT_STAT_DIVIDER,
                  color: AppColors.BORDER,
                ),
                Expanded(
                  child: _Metric(
                    label: AppStrings.FIELD_TRIP_CITY,
                    value: trip.city.name,
                  ),
                ),
                Container(
                  width: AppSizes.BORDER_THIN,
                  height: AppSizes.CLIENT_STAT_DIVIDER,
                  color: AppColors.BORDER,
                ),
                Expanded(
                  child: _Metric(
                    label: AppStrings.FIELD_TRIP_VILLAGE,
                    value: trip.village,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AwaitingApprovalNotice extends StatelessWidget {
  const _AwaitingApprovalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.SMD12),
      decoration: BoxDecoration(
        color: AppColors.WARNING_LIGHT,
        border: Border.all(color: AppColors.WARNING_BORDER),
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: AppSizes.ICON_MD,
            color: AppColors.WARNING,
          ),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.FIELD_TRIP_AWAITING_APPROVAL,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.WARNING,
                  ),
                ),
                const SizedBox(height: AppSpacing.XXS2),
                Text(
                  AppStrings.FIELD_TRIP_AWAITING_APPROVAL_BODY,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.WARNING,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final FieldTrip trip;

  const _PlanCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle(
            icon: Icons.event_outlined,
            title: AppStrings.FIELD_TRIP_PLAN,
          ),
          _DetailRow(
            label: AppStrings.FIELD_TRIP_EXPECTED_START,
            value: DateFormatter.dayTimeFull(trip.expectedStartAt),
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.FIELD_TRIP_EXPECTED_END,
            value: DateFormatter.dayTimeFull(trip.expectedEndAt),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final FieldTrip trip;

  const _TimelineCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle(
            icon: Icons.timeline_rounded,
            title: AppStrings.FIELD_TRIP_PROGRESS,
          ),
          FieldTripTimeline(trip: trip),
        ],
      ),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  final FieldTrip trip;

  const _PeopleCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle(
            icon: Icons.badge_outlined,
            title: AppStrings.FIELD_TRIP_PEOPLE,
          ),
          _DetailRow(
            label: AppStrings.FIELD_TRIP_SALES_PERSON,
            value: trip.salesPerson.name,
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.FIELD_TRIP_APPROVED_BY,
            value: trip.approvedBy?.name ??
                AppStrings.FIELD_TRIP_AWAITING_APPROVAL,
          ),
        ],
      ),
    );
  }
}

class _FarmersCard extends StatelessWidget {
  final FieldTripDetailState state;

  const _FarmersCard({required this.state});

  /// Enough to show the trip went somewhere without the card becoming the
  /// whole screen; the rest are a tap away.
  static const int _maxInline = 5;

  @override
  Widget build(BuildContext context) {
    final List<FarmerVisit> farmers = state.farmers;

    final List<FarmerVisit> shown = farmers.take(_maxInline).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(
            icon: Icons.groups_outlined,
            title: AppStrings.FIELD_TRIP_FARMERS,
            trailing: farmers.isEmpty ? null : '${farmers.length}',
          ),
          if (state.isLoadingFarmers && farmers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.LG24),
              child: Center(
                child: SizedBox(
                  width: AppSizes.ICON_LG,
                  height: AppSizes.ICON_LG,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.BORDER_MEDIUM,
                    color: AppColors.PRIMARY,
                  ),
                ),
              ),
            )
          else if (state.farmersErrorMessage != null && farmers.isEmpty)
            _CardMessage(text: state.farmersErrorMessage!)
          else if (farmers.isEmpty)
            _CardMessage(
              text: state.trip.canRecordFarmer
                  ? AppStrings.FIELD_TRIP_FARMERS_EMPTY_RUNNING
                  : AppStrings.FIELD_TRIP_FARMERS_EMPTY,
            )
          else ...[
            for (int index = 0; index < shown.length; index++) ...[
              if (index > 0) const _RowSeparator(),
              FarmerVisitTile(
                visit: shown[index],
                onTap: () async {
                  final bool? changed = await FarmerDetailScreen.push(
                    context,
                    visit: shown[index],
                    trip: state.trip,
                  );
                  if ((changed ?? false) && context.mounted) {
                    context.read<FieldTripDetailCubit>().loadFarmers();
                  }
                },
              ),
            ],
            if (farmers.length > _maxInline) ...[
              const _RowSeparator(),
              _ViewAllFarmers(
                count: farmers.length,
                onTap: () => TripFarmersScreen.push(
                  context,
                  farmers: farmers,
                  availableFilters: state.farmerFilters,
                  availableSorts: state.farmerSorts,
                  trip: state.trip,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The way into the full, filterable list once a trip has more farmers
/// than the card shows.
class _ViewAllFarmers extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ViewAllFarmers({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.MD16,
          vertical: AppSpacing.SMD12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${AppStrings.FIELD_TRIP_FARMERS_VIEW_ALL} ($count)',
              style: AppTypography.label.copyWith(color: AppColors.PRIMARY),
            ),
            const SizedBox(width: AppSpacing.XS4),
            const Icon(
              Icons.chevron_right_rounded,
              size: AppSizes.ICON_MD,
              color: AppColors.PRIMARY,
            ),
          ],
        ),
      ),
    );
  }
}

/// One action at a time, chosen by where the trip is in its lifecycle. A
/// trip waiting on approval or already finished gets no bar at all rather
/// than a disabled button that invites a tap.
class _PrimaryAction extends StatelessWidget {
  final FieldTripDetailState state;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onRecordFarmer;

  const _PrimaryAction({
    required this.state,
    required this.onStart,
    required this.onEnd,
    required this.onRecordFarmer,
  });

  @override
  Widget build(BuildContext context) {
    final FieldTrip trip = state.trip;

    if (trip.canStart) {
      return _Bar(
        child: PrimaryButton(
          label: AppStrings.FIELD_TRIP_START,
          icon: Icons.play_arrow_rounded,
          isLoading: state.isActing,
          onPressed: onStart,
        ),
      );
    }

    if (trip.canEnd) {
      return _Bar(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: AppStrings.FIELD_TRIP_ADD_FARMER,
                icon: Icons.person_add_alt_rounded,
                onPressed: state.isActing ? null : onRecordFarmer,
              ),
            ),
            const SizedBox(width: AppSpacing.SM8),
            Expanded(
              child: PrimaryButton(
                label: AppStrings.FIELD_TRIP_END,
                isDangerous: true,
                isLoading: state.isActing,
                onPressed: onEnd,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _Bar extends StatelessWidget {
  final Widget child;

  const _Bar({required this.child});

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareFooter(
      applyKeyboardInset: false,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasised;

  const _Metric({
    required this.label,
    required this.value,
    this.isEmphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final String shown = value.trim().isEmpty
        ? AppStrings.ORDER_NO_DATE
        : value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          shown,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: isEmphasised ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY,
          ),
        ),
        const SizedBox(height: AppSpacing.XXS2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final String shown = value.trim().isEmpty
        ? AppStrings.ORDER_NO_DATE
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.MD16,
        vertical: AppSpacing.SMD12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Expanded(
            flex: 2,
            child: Text(
              shown,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMessage extends StatelessWidget {
  final String text;

  const _CardMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        0,
        AppSpacing.MD16,
        AppSpacing.MD16,
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.TEXT_SECONDARY,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final String? count = trailing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        AppSpacing.MD16,
        AppSpacing.MD16,
        AppSpacing.SM8,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.ICON_MD, color: AppColors.PRIMARY),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(child: Text(title, style: AppTypography.labelStrong)),
          if (count != null)
            Text(
              count,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
        ],
      ),
    );
  }
}

class _RowSeparator extends StatelessWidget {
  const _RowSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
      child: Divider(
        height: AppSizes.DIVIDER_THIN,
        thickness: AppSizes.DIVIDER_THIN,
        color: AppColors.DIVIDER,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
