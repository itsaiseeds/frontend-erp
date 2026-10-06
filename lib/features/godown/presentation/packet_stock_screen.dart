import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/godown_repository.dart';
import '../data/models/packet_stock_draft_line.dart';
import '../data/models/stock_table_query.dart';
import 'bloc/packet_stock_cubit.dart';
import 'bloc/packet_stock_state.dart';
import 'fast_mode_screen.dart';
import 'widgets/fast_mode_row.dart';
import 'widgets/godown_card_shimmer.dart';
import 'widgets/stock_table.dart';
import 'widgets/stock_table_view.dart';

class PacketStockScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const PacketStockScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PacketStockCubit>(
      create: (context) => PacketStockCubit(
        repository: GodownRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: _PacketStockView(onMenuTap: onMenuTap),
    );
  }
}

class _PacketStockView extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const _PacketStockView({this.onMenuTap});

  @override
  State<_PacketStockView> createState() => _PacketStockViewState();
}

class _PacketStockViewState extends State<_PacketStockView> {
  final TextEditingController _searchController = TextEditingController();
  StockTableQuery _query = const StockTableQuery();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setQuery(StockTableQuery query) => setState(() => _query = query);

  Future<void> _openFastMode(
    PacketStockCubit cubit,
    PacketStockState state,
  ) async {
    final List<PacketStockDraftLine> lines = state.lines;
    await FastModeScreen.push(
      context,
      title: AppStrings.PACKET_STOCK_TITLE,
      unitLabel: AppStrings.STOCK_PACKETS_UNIT,
      rows: [
        for (final PacketStockDraftLine line in lines)
          FastModeRow(
            key: line.draftKey,
            title: line.packaging.product.name,
            subtitle: '${line.packetWeight} kg',
            imageUrl: line.packaging.product.imageUrl,
            draftCount: line.draftCount,
          ),
      ],
      onCountChanged: cubit.setDraftCount,
      onSubmit: () => _submit(cubit),
    );
    if (mounted) setState(() {});
  }

  Future<bool> _submit(PacketStockCubit cubit) async {
    final bool ok = await cubit.submitDraft();
    if (!mounted) return ok;
    if (ok) {
      ToastUtils.showSuccess(context, AppStrings.STOCK_SUBMIT_SUCCESS);
    } else if (cubit.state.errorMessage != null) {
      ToastUtils.showServerError(context, cubit.state.errorMessage!);
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PacketStockCubit, PacketStockState>(
      builder: (context, state) {
        final PacketStockCubit cubit = context.read<PacketStockCubit>();

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
                AppStrings.PACKET_STOCK_TITLE,
                style: AppTypography.titleMedium,
              ),
              actions: [
                TextButton(
                  onPressed: state.lines.isEmpty
                      ? null
                      : () => _openFastMode(cubit, state),
                  child: Text(
                    AppStrings.STOCK_FILL_STOCK,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.PRIMARY,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.XS6),
              ],
            ),
            body: _Body(
              state: state,
              cubit: cubit,
              query: _query,
              searchController: _searchController,
              onQueryChanged: _setQuery,
              onOpenFillStock: () => _openFastMode(cubit, state),
            ),
            // Saving is only reachable through the confirmed Update on the
            // Fill Stock review page.
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final PacketStockState state;
  final PacketStockCubit cubit;
  final StockTableQuery query;
  final TextEditingController searchController;
  final ValueChanged<StockTableQuery> onQueryChanged;
  final VoidCallback onOpenFillStock;

  const _Body({
    required this.state,
    required this.cubit,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
    required this.onOpenFillStock,
  });

  @override
  Widget build(BuildContext context) {
    if (state.status == PacketStockStatus.loading && state.packagings.isEmpty) {
      // Table skeleton, not the card one: this page renders a table once
      // loaded, and horizontal padding has to match `StockTableView`'s list so
      // the header does not jump sideways when the rows arrive.
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
        child: GodownTableShimmer(),
      );
    }

    if (state.status == PacketStockStatus.failure && state.packagings.isEmpty) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: AppStrings.SOMETHING_WENT_WRONG,
        body: state.errorMessage ?? '',
        onRefresh: cubit.load,
      );
    }

    if (state.packagings.isEmpty) {
      return _Message(
        icon: Icons.scale_outlined,
        title: AppStrings.STOCK_NO_PACKAGINGS_TITLE,
        body: AppStrings.STOCK_NO_PACKAGINGS_BODY,
        onRefresh: cubit.load,
      );
    }

    return StockTableView(
      isComplete: state.isComplete,
      query: query,
      searchController: searchController,
      entries: [
        for (final PacketStockDraftLine line in _filter(state.lines))
          StockTableEntry(
            title: line.packaging.product.name,
            subtitle: '${line.packetWeight} kg',
            available: line.position?.available,
          ),
      ],
      onSearchChanged: (value) => onQueryChanged(query.copyWith(search: value)),
      onClearSearch: () {
        searchController.clear();
        onQueryChanged(query.copyWith(search: ''));
      },
      onFilterApplied: onQueryChanged,
      onOpenFillStock: onOpenFillStock,
      onRefresh: cubit.load,
    );
  }

  /// Search, filter and sort run over the already loaded lines, so nothing
  /// here costs a network round trip.
  List<PacketStockDraftLine> _filter(List<PacketStockDraftLine> lines) {
    final List<PacketStockDraftLine> matched = [
      for (final PacketStockDraftLine line in lines)
        if (query.filter.matches(hasPosition: line.position != null) &&
            stockRowMatches(
              query: query.search,
              title: line.packaging.product.name,
              subtitle: line.packetWeight,
            ))
          line,
    ];

    matched.sort(
      (PacketStockDraftLine a, PacketStockDraftLine b) => compareStockRows(
        query.sort,
        title: a.packaging.product.name,
        available: a.position?.available,
        otherTitle: b.packaging.product.name,
        otherAvailable: b.position?.available,
      ),
    );
    return matched;
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Future<void> Function() onRefresh;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRefresh,
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
