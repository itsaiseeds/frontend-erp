import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../clients/data/models/clients_query.dart';
import '../../clients/presentation/widgets/clients_filter_sheet.dart';
import '../../godown/presentation/widgets/godown_card.dart';
import '../../godown/presentation/widgets/godown_card_shimmer.dart';
import '../../products/presentation/widgets/products_search_bar.dart';
import '../data/lab_tester_repository.dart';
import '../data/models/lab_testing.dart';
import 'bloc/lab_testings_cubit.dart';
import 'bloc/lab_testings_state.dart';
import 'lab_testing_detail_screen.dart';
import 'widgets/lab_result_badge.dart';

/// Every lab test, newest first. A card opens the full report; that screen
/// holds the Edit action, so these rows only navigate.
class LabReportsScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const LabReportsScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LabTestingsCubit>(
      create: (context) => LabTestingsCubit(
        repository: LabTesterRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: _LabReportsView(onMenuTap: onMenuTap),
    );
  }
}

class _LabReportsView extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const _LabReportsView({this.onMenuTap});

  @override
  State<_LabReportsView> createState() => _LabReportsViewState();
}

class _LabReportsViewState extends State<_LabReportsView> {
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
      context.read<LabTestingsCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final LabTestingsCubit cubit = context.read<LabTestingsCubit>();
    final LabTestingsState state = cubit.state;

    final ClientsQuery? applied = await ClientsFilterSheet.show(
      context,
      filters: state.availableFilters,
      sorts: state.availableSorts,
      query: state.query,
    );
    if (applied == null) return;
    await cubit.applyQuery(applied);
  }

  Future<void> _openDetail(LabTesting test) async {
    final LabTestingsCubit cubit = context.read<LabTestingsCubit>();
    await LabTestingDetailScreen.push(context, test: test, cubit: cubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LabTestingsCubit, LabTestingsState>(
      builder: (context, state) {
        final LabTestingsCubit cubit = context.read<LabTestingsCubit>();

        return DismissKeyboard(
          child: Scaffold(
            backgroundColor: AppColors.BACKGROUND,
            appBar: AppBar(
              backgroundColor: AppColors.SURFACE,
              surfaceTintColor: AppColors.TRANSPARENT,
              elevation: 0,
              leading: widget.onMenuTap == null
                  ? null
                  : IconButton(
                      onPressed: widget.onMenuTap,
                      icon: const Icon(Icons.menu_rounded),
                    ),
              title: Text(
                AppStrings.LAB_REPORTS_TITLE,
                style: AppTypography.titleMedium,
              ),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: ProductsSearchBar(
                          controller: _searchController,
                          hintText: AppStrings.LAB_REPORTS_SEARCH_HINT,
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.MD16,
                  ),
                  child: _ResultSummary(
                    count: state.totalCount,
                    isLoaded:
                        state.status == LabTestingsStatus.loaded &&
                        !state.hasNoSearchMatch,
                    hasFilters: state.query.hasFilters,
                    onClear: cubit.clearFilters,
                  ),
                ),
                Expanded(
                  child: _Body(
                    state: state,
                    scrollController: _scrollController,
                    onRefresh: cubit.refresh,
                    onTap: _openDetail,
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

class _ResultSummary extends StatelessWidget {
  final int count;
  final bool isLoaded;
  final bool hasFilters;
  final VoidCallback onClear;

  const _ResultSummary({
    required this.count,
    required this.isLoaded,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) return const SizedBox.shrink();

    final String noun = count == 1
        ? AppStrings.LAB_REPORT_COUNT_ONE
        : AppStrings.LAB_REPORT_COUNT_MANY;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.SM8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$count $noun',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: AppSpacing.SMD12),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.CLIENTS_CLEAR_ALL,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LabTestingsState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(LabTesting) onTap;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == LabTestingsStatus.loading && state.tests.isEmpty) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.SMD12),
        child: GodownCardShimmer(),
      );
    }

    if (state.status == LabTestingsStatus.failure && state.tests.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.error_outline_rounded,
        title: AppStrings.SOMETHING_WENT_WRONG,
        body: state.errorMessage ?? '',
      );
    }

    if (state.hasNoSearchMatch) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.search_off_rounded,
        title: AppStrings.LAB_NO_SEARCH_MATCH,
        body: '',
      );
    }

    if (state.tests.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        icon: Icons.fact_check_outlined,
        title: AppStrings.LAB_REPORTS_EMPTY_TITLE,
        body: AppStrings.LAB_REPORTS_EMPTY_BODY,
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
          AppSizes.ORDER_LIST_BOTTOM_INSET,
        ),
        itemCount: state.tests.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.SMD12),
        itemBuilder: (context, index) {
          if (index >= state.tests.length) {
            return const GodownCardShimmerTile();
          }

          final LabTesting test = state.tests[index];
          return GodownCard(
            icon: Icons.fact_check_outlined,
            title: test.inwardRawMaterial.product.name,
            tagLabel: test.inwardRawMaterial.party.name,
            codeLabel: test.inwardRawMaterial.lotNo,
            trailing: LabResultBadge(result: test.result, isCompact: true),
            onTap: () => onTap(test),
            stats: [
              GodownCardStat(
                label: AppStrings.LAB_TEST_GROW_OUT_TEST,
                value: '${test.growOutTest}%',
                valueColor: AppColors.PRIMARY,
              ),
              GodownCardStat(
                label: AppStrings.LAB_TEST_GENETICAL_IMPURITY,
                value: '${test.geneticalImpurity}%',
              ),
              GodownCardStat(
                label: AppStrings.LAB_TEST_FIELD_TESTED_AT,
                value: DateFormatter.dayShort(test.testedAt),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RefreshableMessage extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final IconData icon;
  final String title;
  final String body;

  const _RefreshableMessage({
    required this.onRefresh,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.PRIMARY,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.XXXL80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppSizes.ICON_XXL,
                  color: AppColors.TEXT_DISABLED,
                ),
                const SizedBox(height: AppSpacing.MD16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium,
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.SM8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.XL32,
                    ),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.TEXT_SECONDARY,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}