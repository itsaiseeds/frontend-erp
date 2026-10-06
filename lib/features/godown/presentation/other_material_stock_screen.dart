import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../products/presentation/widgets/products_search_bar.dart';
import '../data/godown_repository.dart';
import '../data/models/godown_stock.dart';
import 'widgets/godown_card.dart';
import 'widgets/godown_card_shimmer.dart';

class OtherMaterialStockScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const OtherMaterialStockScreen({super.key, this.onMenuTap});

  @override
  State<OtherMaterialStockScreen> createState() =>
      _OtherMaterialStockScreenState();
}

class _OtherMaterialStockScreenState extends State<OtherMaterialStockScreen> {
  late final GodownRepository _repository = GodownRepository(
    apiClient: context.read<ApiClient>(),
  );

  final TextEditingController _searchController = TextEditingController();

  OtherMaterialStock? _stock;
  String _search = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final OtherMaterialStock stock = await _repository
          .fetchOtherMaterialStock();
      if (!mounted) return;
      setState(() {
        _stock = stock;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  List<OtherMaterialStockLine> get _visibleLines {
    final List<OtherMaterialStockLine> lines = _stock?.lines ?? const [];
    final String needle = _search.trim().toLowerCase();
    if (needle.isEmpty) return lines;
    return [
      for (final line in lines)
        if (line.materialType.name.toLowerCase().contains(needle)) line,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<OtherMaterialStockLine> visible = _visibleLines;

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
            AppStrings.OTHER_MATERIAL_STOCK_TITLE,
            style: AppTypography.titleMedium,
          ),
        ),
        body: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.SMD12),
                child: GodownCardShimmer(),
              )
            : _error != null
            ? _Message(
                icon: Icons.error_outline_rounded,
                title: AppStrings.SOMETHING_WENT_WRONG,
                body: _error!,
                onRefresh: _load,
              )
            : Column(
                children: [
                  if ((_stock?.lines ?? const []).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.MD16,
                        AppSpacing.SMD12,
                        AppSpacing.MD16,
                        AppSpacing.SM8,
                      ),
                      child: ProductsSearchBar(
                        controller: _searchController,
                        hintText: AppStrings.INWARD_OTHER_SEARCH_HINT,
                        onChanged: (value) => setState(() => _search = value),
                        onSubmitted: (value) =>
                            FocusScope.of(context).unfocus(),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                    ),
                  Expanded(
                    child: (_stock == null || _stock!.lines.isEmpty)
                        ? _Message(
                            icon: Icons.inventory_2_outlined,
                            title: AppStrings.STOCK_EMPTY_TITLE,
                            body: AppStrings.STOCK_EMPTY_BODY,
                            onRefresh: _load,
                          )
                        : visible.isEmpty
                        ? _Message(
                            icon: Icons.search_off_rounded,
                            title: AppStrings.INWARD_NO_SEARCH_MATCH,
                            body: '',
                            onRefresh: _load,
                          )
                        : Column(
                            children: [
                              if (_stock!.asOf != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.MD16,
                                    0,
                                    AppSpacing.MD16,
                                    AppSpacing.SM8,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${AppStrings.STOCK_AS_OF} ${DateFormatter.calendarDay(_stock!.asOf)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.TEXT_SECONDARY,
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: RefreshIndicator(
                                  color: AppColors.PRIMARY,
                                  onRefresh: _load,
                                  child: ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.SMD12,
                                      0,
                                      AppSpacing.SMD12,
                                      AppSizes.ORDER_LIST_BOTTOM_INSET,
                                    ),
                                    itemCount: visible.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(
                                          height: AppSpacing.SMD12,
                                        ),
                                    itemBuilder: (context, index) {
                                      final OtherMaterialStockLine line =
                                          visible[index];
                                      return GodownCard(
                                        icon: Icons.category_outlined,
                                        title: line.materialType.name,
                                        tagLabel: line.isShort
                                            ? AppStrings.STOCK_SHORTFALL
                                            : null,
                                        tagColor: AppColors.ERROR,
                                        stats: [
                                          GodownCardStat(
                                            label: AppStrings.STOCK_ON_HAND,
                                            value:
                                                '${line.onHand} ${line.materialType.unitType}',
                                            valueColor: line.isShort
                                                ? AppColors.ERROR
                                                : AppColors.PRIMARY,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
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
