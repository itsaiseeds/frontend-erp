import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/field_trips_repository.dart';
import '../../products/presentation/widgets/products_search_bar.dart';
import '../data/models/field_trip.dart';
import 'bloc/field_trips_cubit.dart';
import 'bloc/field_trips_state.dart';
import 'field_trip_detail_screen.dart';
import 'field_trip_form_screen.dart';
import 'widgets/field_trip_card.dart';
import 'widgets/field_trip_status_filter.dart';

class FieldTripsScreen extends StatelessWidget {
  const FieldTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FieldTripsCubit>(
      create: (context) => FieldTripsCubit(
        repository: FieldTripsRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: const _FieldTripsView(),
    );
  }
}

class _FieldTripsView extends StatefulWidget {
  const _FieldTripsView();

  @override
  State<_FieldTripsView> createState() => _FieldTripsViewState();
}

class _FieldTripsViewState extends State<_FieldTripsView> {
  static const double _loadMoreThreshold = 320;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final double remaining =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining <= _loadMoreThreshold) {
      context.read<FieldTripsCubit>().loadMore();
    }
  }

  Future<void> _planTrip() async {
    final FieldTripsCubit cubit = context.read<FieldTripsCubit>();
    final bool? saved = await FieldTripFormScreen.push(context);
    if (saved ?? false) await cubit.refresh();
  }

  Future<void> _openDetail(FieldTrip trip) async {
    final FieldTripsCubit cubit = context.read<FieldTripsCubit>();
    final bool? changed = await FieldTripDetailScreen.push(context, trip: trip);
    if (changed ?? false) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldTripsCubit, FieldTripsState>(
      builder: (context, state) {
        final FieldTripsCubit cubit = context.read<FieldTripsCubit>();

        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          floatingActionButton: FloatingActionButton(
            onPressed: _planTrip,
            backgroundColor: AppColors.PRIMARY,
            foregroundColor: AppColors.TEXT_ON_PRIMARY,
            elevation: 0,
            highlightElevation: 0,
            tooltip: AppStrings.FIELD_TRIP_PLAN_TOOLTIP,
            child: const Icon(Icons.add_rounded, size: AppSizes.ICON_XL),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.MD16,
                  AppSpacing.SMD12,
                  AppSpacing.MD16,
                  AppSpacing.SM8,
                ),
                child: ProductsSearchBar(
                  controller: _searchController,
                  hintText: AppStrings.FIELD_TRIP_SEARCH_HINT,
                  onChanged: (_) {},
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    cubit.searchVillage(value);
                  },
                  onClear: () {
                    _searchController.clear();
                    cubit.searchVillage('');
                  },
                ),
              ),
              FieldTripStatusFilter(
                selected: state.query.status,
                onChanged: cubit.selectStatus,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.MD16,
                  AppSpacing.SMD12,
                  AppSpacing.MD16,
                  0,
                ),
                child: _ResultSummary(
                  count: state.totalCount,
                  isLoaded: state.status == FieldTripsStatus.loaded,
                ),
              ),
              Expanded(
                child: _Body(
                  state: state,
                  scrollController: _scrollController,
                  onRefresh: cubit.refresh,
                  onTapTrip: _openDetail,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final FieldTripsState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(FieldTrip) onTapTrip;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onTapTrip,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.trips.isEmpty) {
      return RefreshIndicator(
        color: AppColors.PRIMARY,
        onRefresh: onRefresh,
        child: const _FieldTripListShimmer(),
      );
    }

    if (state.status == FieldTripsStatus.failure) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.error_outline_rounded,
          title: AppStrings.FIELD_TRIPS_ERROR_TITLE,
          body: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }

    if (state.trips.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: const _Message(
          icon: Icons.map_outlined,
          title: AppStrings.FIELD_TRIPS_EMPTY_TITLE,
          body: AppStrings.FIELD_TRIPS_EMPTY_BODY,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.SMD12,
          AppSpacing.SM8,
          AppSpacing.SMD12,
          AppSizes.FIELD_TRIP_LIST_BOTTOM_INSET,
        ),
        itemCount: state.trips.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.SMD12),
        itemBuilder: (context, index) {
          if (index >= state.trips.length) return const _LoadMoreIndicator();

          final FieldTrip trip = state.trips[index];
          return FieldTripCard(trip: trip, onTap: () => onTapTrip(trip));
        },
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.MD16),
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
    );
  }
}

class _FieldTripListShimmer extends StatelessWidget {
  static const int _placeholderCount = 4;

  const _FieldTripListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SM8,
        AppSpacing.SMD12,
        AppSizes.FIELD_TRIP_LIST_BOTTOM_INSET,
      ),
      itemCount: _placeholderCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.SMD12),
      itemBuilder: (context, index) => Container(
        height: AppSizes.FIELD_TRIP_CARD_HEIGHT,
        decoration: BoxDecoration(
          color: AppColors.SURFACE,
          border: Border.all(color: AppColors.BORDER),
          borderRadius: BorderRadius.circular(AppRadius.XL),
        ),
      ),
    );
  }
}

class _RefreshableMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _RefreshableMessage({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
            const SizedBox(height: AppSpacing.SMD12),
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.XS6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final int count;
  final bool isLoaded;

  const _ResultSummary({required this.count, required this.isLoaded});

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) return const SizedBox.shrink();

    final String noun = count == 1
        ? AppStrings.FIELD_TRIPS_COUNT_ONE
        : AppStrings.FIELD_TRIPS_COUNT_MANY;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$count $noun',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.TEXT_SECONDARY,
        ),
      ),
    );
  }
}
