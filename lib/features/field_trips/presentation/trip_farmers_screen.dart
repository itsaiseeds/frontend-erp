import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../clients/data/models/client_filter.dart';
import '../../clients/data/models/clients_query.dart';
import '../../clients/presentation/widgets/clients_filter_sheet.dart';
import '../../products/presentation/widgets/products_search_bar.dart';
import '../data/models/farmer_visit.dart';
import '../data/models/field_trip.dart';
import 'farmer_detail_screen.dart';
import 'widgets/farmer_visit_tile.dart';

/// Every farmer recorded on one trip, filterable by crop and product.
///
/// The whole set is already in hand -- the trip endpoint sends it with
/// ``all=true`` -- so the filtering happens here rather than as another
/// round trip for a list that is a day's visits, not a catalogue.
class TripFarmersScreen extends StatefulWidget {
  final List<FarmerVisit> farmers;
  final List<ClientFilter> availableFilters;
  final List<ClientSort> availableSorts;

  /// Carried through so a farmer opened from here can still be edited
  /// while the trip is running.
  final FieldTrip? trip;

  const TripFarmersScreen({
    super.key,
    required this.farmers,
    this.availableFilters = const [],
    this.availableSorts = const [],
    this.trip,
  });

  /// The filter and sort keys the farmer-visit endpoint publishes.
  static const String cropFilter = 'crop';
  static const String productFilter = 'product';
  static const String usesProductsFilter = 'uses_our_products';
  static const String sortRecorded = 'created_at';
  static const String sortLandArea = 'land_area';
  static const String sortFarmerName = 'farmer_name';

  static Future<void> push(
    BuildContext context, {
    required List<FarmerVisit> farmers,
    List<ClientFilter> availableFilters = const [],
    List<ClientSort> availableSorts = const [],
    FieldTrip? trip,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TripFarmersScreen(
          farmers: farmers,
          availableFilters: availableFilters,
          availableSorts: availableSorts,
          trip: trip,
        ),
      ),
    );
  }

  @override
  State<TripFarmersScreen> createState() => _TripFarmersScreenState();
}

class _TripFarmersScreenState extends State<TripFarmersScreen> {
  final TextEditingController _searchController = TextEditingController();

  ClientsQuery _query = const ClientsQuery();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// When the server sent no catalogue, one is built from what the trip
  /// actually holds: the sheet needs options either way, and these are
  /// exactly the values that can match.
  List<ClientFilter> get _filters {
    if (widget.availableFilters.isNotEmpty) return widget.availableFilters;

    final Map<String, String> crops = {
      for (final FarmerVisit visit in widget.farmers)
        for (final FarmerCrop crop in visit.crops)
          if (crop.name.trim().isNotEmpty) '${crop.id}': crop.name,
    };
    final Map<String, String> products = {
      for (final FarmerVisit visit in widget.farmers)
        for (final FarmerProduct product in visit.products)
          if (product.name.trim().isNotEmpty) product.publicId: product.name,
    };

    return [
      if (crops.isNotEmpty)
        ClientFilter(
          key: TripFarmersScreen.cropFilter,
          kind: FilterKind.select,
          label: AppStrings.FARMER_VISIT_CROPS,
          options: [
            for (final MapEntry<String, String> entry in crops.entries)
              FilterOption(value: entry.key, label: entry.value),
          ],
        ),
      if (products.isNotEmpty)
        ClientFilter(
          key: TripFarmersScreen.productFilter,
          kind: FilterKind.select,
          label: AppStrings.FARMER_VISIT_PRODUCTS,
          options: [
            for (final MapEntry<String, String> entry in products.entries)
              FilterOption(value: entry.key, label: entry.value),
          ],
        ),
      const ClientFilter(
        key: TripFarmersScreen.usesProductsFilter,
        kind: FilterKind.select,
        label: AppStrings.FARMER_VISIT_USES_PRODUCTS,
        options: [
          FilterOption(value: 'true', label: AppStrings.YES),
          FilterOption(value: 'false', label: AppStrings.NO),
        ],
      ),
    ];
  }

  List<FarmerVisit> get _visible {
    final Set<String> crops =
        _query.selections[TripFarmersScreen.cropFilter] ?? const {};
    final Set<String> products =
        _query.selections[TripFarmersScreen.productFilter] ?? const {};
    final Set<String> usesOurs =
        _query.selections[TripFarmersScreen.usesProductsFilter] ?? const {};
    final String needle = _search.trim().toLowerCase();

    final List<FarmerVisit> matched = [
      for (final FarmerVisit visit in widget.farmers)
        if ((needle.isEmpty ||
                visit.farmerName.toLowerCase().contains(needle) ||
                visit.contactNumber.contains(needle)) &&
            // A farmer matches when any one of their crops is picked, the
            // way the server's own crop= filter behaves.
            (crops.isEmpty ||
                visit.crops.any((crop) => crops.contains('${crop.id}'))) &&
            (products.isEmpty ||
                visit.products.any(
                  (product) => products.contains(product.publicId),
                )) &&
            _matchesProductUse(visit, usesOurs))
          visit,
    ];

    return _sorted(matched);
  }

  /// Yes means at least one of our products; no means none. Picking both
  /// is the same as picking neither, so it is not treated as a filter.
  bool _matchesProductUse(FarmerVisit visit, Set<String> selected) {
    if (selected.isEmpty || selected.length > 1) return true;

    final bool wantsUsers = selected.first.toLowerCase() == 'true';
    return visit.products.isNotEmpty == wantsUsers;
  }

  /// Sorted in memory, by the same keys the endpoint offers.
  List<FarmerVisit> _sorted(List<FarmerVisit> visits) {
    final String? key = _query.sort;
    if (key == null) return visits;

    final List<FarmerVisit> sorted = [...visits];
    sorted.sort((a, b) {
      switch (key) {
        case TripFarmersScreen.sortLandArea:
          return a.landAreaBigha.compareTo(b.landAreaBigha);
        case TripFarmersScreen.sortFarmerName:
          return a.farmerName.toLowerCase().compareTo(
            b.farmerName.toLowerCase(),
          );
        case TripFarmersScreen.sortRecorded:
        default:
          final DateTime? left = a.createdAt;
          final DateTime? right = b.createdAt;
          if (left == null && right == null) return 0;
          // A visit with no stamp sorts last whichever way the list runs.
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
      }
    });

    return _query.descending ? sorted.reversed.toList() : sorted;
  }

  Future<void> _openFilters() async {
    final ClientsQuery? applied = await ClientsFilterSheet.show(
      context,
      filters: _filters,
      sorts: widget.availableSorts,
      query: _query,
    );
    if (applied == null) return;
    setState(() => _query = applied);
  }

  void _clearFilters() => setState(() => _query = const ClientsQuery());

  @override
  Widget build(BuildContext context) {
    final List<FarmerVisit> visible = _visible;

    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUND,
        appBar: AppBar(
          backgroundColor: AppColors.SURFACE,
          surfaceTintColor: AppColors.TRANSPARENT,
          elevation: 0,
          titleSpacing: 0,
          leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: AppSizes.ICON_XL,
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
          title: Text(
            AppStrings.FIELD_TRIP_FARMERS_TITLE,
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
                      hintText: AppStrings.FARMER_SEARCH_HINT,
                      onChanged: (value) => setState(() => _search = value),
                      onSubmitted: (value) {
                        FocusScope.of(context).unfocus();
                        setState(() => _search = value);
                      },
                      onClear: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.SM8),
                  _FilterButton(
                    activeCount: _query.activeCount,
                    onTap: _openFilters,
                  ),
                ],
              ),
            ),
            _ResultBar(
              count: visible.length,
              hasFilters: _query.activeCount > 0,
              onClear: _clearFilters,
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.XL32),
                        child: Text(
                          AppStrings.FARMER_FILTER_NONE_MATCH,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.TEXT_SECONDARY,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.NOTIFICATION_LIST_BOTTOM_INSET,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.BORDER,
                      ),
                      itemBuilder: (context, index) {
                        final FarmerVisit visit = visible[index];
                        return Material(
                          color: AppColors.SURFACE,
                          child: FarmerVisitTile(
                            visit: visit,
                            onTap: () =>
                                FarmerDetailScreen.push(
                                  context,
                                  visit: visit,
                                  trip: widget.trip,
                                ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crops and products on one scrolling line, with a clear that only
/// appears once something is filtered.
///
/// Two stacked rows of pills pushed the first farmer below the fold, which
/// is the opposite of what a filter is for.
/// The same tune control the product and order lists carry, so a filter
/// opens the same way wherever the salesperson is.
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
