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
import 'widgets/godown_card_shimmer.dart';
import 'widgets/other_material_product_card.dart';

/// Every line for one product + packet weight -- one card on screen. A
/// product with more than one packaging (e.g. two packet weights) gets one
/// group per configuration, same as the admin table's "Packaging" column.
class _ProductGroup {
  final String productName;
  final String packetWeightLabel;
  final List<OtherMaterialStockLine> lines;

  const _ProductGroup({
    required this.productName,
    required this.packetWeightLabel,
    required this.lines,
  });
}

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

  /// Lines carry their own product + packet weight (the API answers
  /// ``?group_by=configuration``), so grouping only needs to walk the list
  /// once and bucket by that pair -- insertion order is kept, which is
  /// already the API's own order.
  List<_ProductGroup> get _groups {
    final List<OtherMaterialStockLine> lines = _stock?.lines ?? const [];
    final Map<String, List<OtherMaterialStockLine>> buckets = {};

    for (final line in lines) {
      final String key =
          '${line.product?.publicId ?? ''}#${line.packetWeight}';
      (buckets[key] ??= []).add(line);
    }

    return [
      for (final entry in buckets.entries)
        _ProductGroup(
          productName: entry.value.first.product?.name ?? '',
          packetWeightLabel: entry.value.first.packetWeightSummary,
          lines: entry.value,
        ),
    ];
  }

  List<_ProductGroup> get _visibleGroups {
    final List<_ProductGroup> groups = _groups;
    final String needle = _search.trim().toLowerCase();
    if (needle.isEmpty) return groups;
    return [
      for (final group in groups)
        if (group.productName.toLowerCase().contains(needle)) group,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<_ProductGroup> visible = _visibleGroups;

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
                                      final _ProductGroup group =
                                          visible[index];
                                      return OtherMaterialProductCard(
                                        productName: group.productName,
                                        packetWeightLabel:
                                            group.packetWeightLabel,
                                        lines: group.lines,
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
