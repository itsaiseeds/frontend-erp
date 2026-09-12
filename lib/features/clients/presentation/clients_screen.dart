import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/clients_repository.dart';
import '../data/models/client.dart';
import 'bloc/clients_cubit.dart';
import 'bloc/clients_state.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';
import 'widgets/client_card.dart';
import 'widgets/client_card_shimmer.dart';
import 'widgets/client_status_switcher.dart';
import 'widgets/clients_filter_sheet.dart';
import 'widgets/clients_search_bar.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClientsCubit>(
      create: (context) => ClientsCubit(
        repository: ClientsRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: const _ClientsView(),
    );
  }
}

class _ClientsView extends StatefulWidget {
  const _ClientsView();

  @override
  State<_ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<_ClientsView> {
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
      context.read<ClientsCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final ClientsCubit cubit = context.read<ClientsCubit>();
    FocusScope.of(context).unfocus();

    final result = await ClientsFilterSheet.show(
      context,
      filters: cubit.state.availableFilters,
      sorts: cubit.state.availableSorts,
      query: cubit.state.query,
    );

    if (result != null) await cubit.applyQuery(result);
  }

  Future<void> _addClient() async {
    final ClientsCubit cubit = context.read<ClientsCubit>();
    final bool? saved = await ClientFormScreen.push(context);
    if (saved ?? false) await cubit.refresh();
  }

  Future<void> _openDetail(Client client) async {
    final ClientsCubit cubit = context.read<ClientsCubit>();
    final bool? changed = await ClientDetailScreen.push(
      context,
      publicId: client.publicId,
      summary: client,
    );
    if (changed ?? false) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsCubit, ClientsState>(
      builder: (context, state) {
        final ClientsCubit cubit = context.read<ClientsCubit>();

        return Scaffold(
          backgroundColor: AppColors.SURFACE,
          floatingActionButton: FloatingActionButton(
            onPressed: _addClient,
            backgroundColor: AppColors.PRIMARY,
            foregroundColor: AppColors.TEXT_ON_PRIMARY,
            elevation: 0,
            highlightElevation: 0,
            tooltip: AppStrings.CLIENT_ADD_TOOLTIP,
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
                  child: Column(
                    children: [
                      ClientStatusSwitcher(
                        selected: state.statusView,
                        onChanged: cubit.selectStatusView,
                      ),
                      const SizedBox(height: AppSpacing.SMD12),
                      Row(
                        children: [
                          Expanded(
                            child: ClientsSearchBar(
                              controller: _searchController,
                              scope: state.searchScope,
                              onChanged: cubit.updateSearchQuery,
                              onSubmitted: (value) {
                                FocusScope.of(context).unfocus();
                                cubit.submitSearch(value);
                              },
                              onScopeChanged: cubit.setSearchScope,
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
                    ],
                  ),
                ),
                if (state.status == ClientsStatus.loaded)
                  _ResultBar(
                    count: state.visibleClients.length,
                    hasFilters: state.query.hasFilters,
                    onClear: cubit.clearFilters,
                  ),
                Expanded(
                  child: _Body(
                    state: state,
                    scrollController: _scrollController,
                    onRefresh: cubit.refresh,
                    onTapClient: _openDetail,
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
                Container(
                  width: AppSizes.CLIENT_BADGE_COUNT,
                  height: AppSizes.CLIENT_BADGE_COUNT,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.SURFACE,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.PRIMARY,
                    ),
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
              '$count ${count == 1 ? AppStrings.CLIENTS_COUNT_ONE : AppStrings.CLIENTS_COUNT_MANY}',
              style: AppTypography.labelSmall,
            ),
          ),
          if (hasFilters)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.CLIENTS_CLEAR_ALL,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.ERROR,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final ClientsState state;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(Client) onTapClient;

  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRefresh,
    required this.onTapClient,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.clients.isEmpty) {
      return RefreshIndicator(
        color: AppColors.PRIMARY,
        onRefresh: onRefresh,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
          child: ClientCardShimmer(isScrollable: true),
        ),
      );
    }

    if (state.status == ClientsStatus.failure) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.error_outline_rounded,
          title: AppStrings.CLIENTS_ERROR_TITLE,
          body: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
          isError: true,
        ),
      );
    }

    final List<Client> clients = state.visibleClients;

    if (clients.isEmpty) {
      return _RefreshableMessage(
        onRefresh: onRefresh,
        child: const _Message(
          icon: Icons.search_off_rounded,
          title: AppStrings.CLIENTS_EMPTY_TITLE,
          body: AppStrings.CLIENTS_EMPTY_BODY,
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
          AppSizes.CLIENT_LIST_BOTTOM_INSET,
        ),
        itemCount: clients.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.SMD12),
        itemBuilder: (context, index) {
          if (index == clients.length) {
            return _ListFooter(
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
            );
          }

          final Client client = clients[index];
          return ClientCard(client: client, onTap: () => onTapClient(client));
        },
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const _ListFooter({required this.isLoadingMore, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.SM8),
        child: ClientCardShimmer(itemCount: 1),
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
