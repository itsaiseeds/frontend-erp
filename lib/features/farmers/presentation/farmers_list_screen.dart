import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../field_trips/data/models/farmer_visit.dart';
import '../data/farmers_repository.dart';
import 'bloc/farmers_cubit.dart';
import 'bloc/farmers_state.dart';
import 'farmer_detail_screen.dart';
import 'farmer_form_screen.dart';
import 'widgets/farmer_card.dart';
import 'widgets/farmers_filter_sheet.dart';
import 'widgets/farmers_search_bar.dart';

/// Every farmer the sales person has recorded directly, without a farmer
/// meeting behind it -- paginated and filtered/sorted server-side, the
/// counterpart to [TripFarmersScreen]'s in-memory list for one meeting.
class FarmersListScreen extends StatelessWidget {
  const FarmersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FarmersCubit>(
      create: (context) => FarmersCubit(
        repository: FarmersRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: const _FarmersView(),
    );
  }
}

class _FarmersView extends StatefulWidget {
  const _FarmersView();

  @override
  State<_FarmersView> createState() => _FarmersViewState();
}

class _FarmersViewState extends State<_FarmersView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const double _loadMoreThreshold = 320.0;

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
      context.read<FarmersCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final FarmersCubit cubit = context.read<FarmersCubit>();
    FocusScope.of(context).unfocus();

    final result = await FarmersFilterSheet.show(
      context,
      filters: cubit.state.availableFilters,
      sorts: cubit.state.availableSorts,
      query: cubit.state.query,
    );

    if (result != null) await cubit.applyQuery(result);
  }

  Future<void> _addFarmer() async {
    final FarmersCubit cubit = context.read<FarmersCubit>();
    final bool? saved = await FarmerFormScreen.push(context);
    if (saved ?? false) await cubit.refresh();
  }

  Future<void> _openDetail(FarmerVisit farmer) async {
    final FarmersCubit cubit = context.read<FarmersCubit>();
    final bool? changed = await FarmerDetailScreen.push(
      context,
      farmer: farmer,
    );
    if (changed ?? false) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FarmersCubit, FarmersState>(
      builder: (context, state) {
        final FarmersCubit cubit = context.read<FarmersCubit>();

        return Scaffold(
          backgroundColor: AppColors.SURFACE,
          floatingActionButton: FloatingActionButton(
            onPressed: _addFarmer,
            backgroundColor: AppColors.PRIMARY,
            foregroundColor: AppColors.TEXT_ON_PRIMARY,
            elevation: 0,
            highlightElevation: 0,
            tooltip: AppStrings.FARMER_RECORD_ADD_TITLE,
            child: const Icon(Icons.add_rounded, size: AppSizes.ICON_XL),
          ),
          body: DismissKeyboard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.MD16,
                    AppSpacing.SMD12,
                    AppSpacing.MD16,
                    AppSpacing.SM8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FarmersSearchBar(
                          controller: _searchController,
                          onChanged: cubit.updateSearchQuery,
                          onSubmitted: (value) {
                            FocusScope.of(context).unfocus();
                            cubit.submitSearch(value);
                          },
                          onClear: () {
                            _searchController.clear();
                            cubit.clearSearch();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.SM8),
                      _FilterButton(
                        activeCount: state.query.activeCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                ),
                if (state.status == FarmersStatus.loaded)
                  _ResultBar(
                    count: state.farmers.length,
                    hasFilters: state.query.hasFilters,
                    onClear: cubit.clearFilters,
                  ),
                Expanded(
                  child: _Body(
                    state: state,
                    scrollController: _scrollController,
                    onRefresh: cubit.refresh,
                    onTapFarmer: _openDetail,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeCount > 0;

    return Material(
      color: isActive ? AppColors.PRIMARY : AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.CLIENT_FILTER_CONTROL,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.SMD12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? AppColors.PRIMARY : AppColors.BORDER,
            ),
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: AppSizes.ICON_MD,
                color: isActive
                    ? AppColors.TEXT_ON_PRIMARY
                    : AppColors.TEXT_SECONDARY,
              ),
              if (isActive) ...[
                const SizedBox(width: AppSpacing.XS6),
                Text(
                  '$activeCount',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final int count;
  final bool hasFilters;
  final VoidCallback onClear;

  const _ResultBar({
    required this.count,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final String noun = count == 1
        ? AppStrings.FIELD_TRIP_FARMER_COUNT_ONE
        : AppStrings.FIELD_TRIP_FARMER_COUNT_MANY;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        0,
        AppSpacing.MD16,
        AppSpacing.SM8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count $noun',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          if (hasFilters)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.FARMER_FILTER_CLEAR,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final FarmersState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(FarmerVisit) onTapFarmer;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onTapFarmer,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.farmers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.PRIMARY),
      );
    }

    if (state.status == FarmersStatus.failure) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.error_outline_rounded,
          title: AppStrings.FARMERS_LOAD_ERROR,
          body: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
          isError: true,
        ),
      );
    }

    final List<FarmerVisit> farmers = state.farmers;

    if (farmers.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.agriculture_outlined,
          title: state.query.hasFilters || state.query.hasSearch
              ? AppStrings.FARMERS_FILTER_NONE_MATCH
              : AppStrings.FARMERS_EMPTY_TITLE,
          body: AppStrings.FARMERS_EMPTY_BODY,
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
          AppSpacing.MD16,
          0,
          AppSpacing.MD16,
          AppSizes.NOTIFICATION_LIST_BOTTOM_INSET,
        ),
        itemCount: farmers.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.SM8),
        itemBuilder: (context, index) {
          if (index == farmers.length) {
            return _ListFooter(isLoadingMore: state.isLoadingMore);
          }

          final FarmerVisit farmer = farmers[index];
          return FarmerCard(
            farmer: farmer,
            onTap: () => onTapFarmer(farmer),
          );
        },
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final bool isLoadingMore;

  const _ListFooter({required this.isLoadingMore});

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.MD16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.PRIMARY),
        ),
      );
    }

    return const SizedBox(height: AppSpacing.XL32);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.HOME_PLACEHOLDER_MAX_WIDTH,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.HOME_PLACEHOLDER_ICON,
                height: AppSizes.HOME_PLACEHOLDER_ICON,
                decoration: BoxDecoration(
                  color: isError
                      ? AppColors.ERROR_LIGHT
                      : AppColors.PRIMARY_SURFACE,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppSizes.ICON_XXL,
                  color: isError ? AppColors.ERROR : AppColors.PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.LG24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headingSmall,
              ),
              const SizedBox(height: AppSpacing.SM8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
