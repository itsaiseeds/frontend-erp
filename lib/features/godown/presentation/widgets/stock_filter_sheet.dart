import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../data/models/stock_table_query.dart';

/// The groups the sheet edits, in rail order. Count status comes first because
/// it is the one a stock counter reaches for; sorting is the rarer tweak.
enum _Section { countStatus, sort }

extension on _Section {
  String get title => switch (this) {
    _Section.countStatus => AppStrings.STOCK_FILTER_COUNT_STATUS,
    _Section.sort => AppStrings.STOCK_FILTER_SORT,
  };
}

/// Filter/sort sheet for the stock tables. Edits a draft copy so Cancel and the
/// close button really cancel, and hands the new query back only when Apply is
/// pressed.
///
/// Laid out like the app's other filter sheets -- a category rail beside the
/// options, a search box to narrow them, and a Clear all / Apply footer -- so
/// the stock tables feel like the same app as the inward and catalogue lists
/// rather than a one-off dialog. Both controls here are single-select, so the
/// rows read as radio buttons instead of the checkboxes used for multi-select
/// elsewhere.
class StockFilterSheet extends StatefulWidget {
  final StockTableQuery query;

  const StockFilterSheet({super.key, required this.query});

  static Future<StockTableQuery?> show(
    BuildContext context, {
    required StockTableQuery query,
  }) {
    return showModalBottomSheet<StockTableQuery>(
      context: context,
      backgroundColor: AppColors.SURFACE,
      barrierColor: AppColors.OVERLAY,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.SHEET),
        ),
      ),
      builder: (_) => StockFilterSheet(query: query),
    );
  }

  @override
  State<StockFilterSheet> createState() => _StockFilterSheetState();
}

class _StockFilterSheetState extends State<StockFilterSheet> {
  late StockTableQuery _draft;
  late final TextEditingController _searchController;

  _Section _activeSection = _Section.countStatus;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _draft = widget.query;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Mirrors `StockTableQuery.activeCount` section by section, so the rail dots
  /// and the toolbar badge always agree about what counts as active.
  int _activeCountFor(_Section section) => switch (section) {
    _Section.countStatus => _draft.filter == StockCountFilter.all ? 0 : 1,
    _Section.sort => _draft.sort.isDefault ? 0 : 1,
  };

  /// Clear all only touches the two controls this sheet owns. The search text
  /// belongs to the toolbar above, so wiping it here would leave the visible
  /// field disagreeing with the query that gets applied.
  void _clear() {
    setState(() {
      _draft = StockTableQuery(search: _draft.search);
      _searchController.clear();
      _search = '';
    });
  }

  bool _matches(String label) {
    final String needle = _search.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return label.toLowerCase().contains(needle);
  }

  List<String> get _optionLabels => switch (_activeSection) {
    _Section.countStatus => [
      for (final StockCountFilter option in StockCountFilter.values)
        option.label,
    ],
    _Section.sort => [
      for (final StockSort option in StockSort.values) option.label,
    ],
  };

  Widget _buildOptions() {
    final List<String> labels = _optionLabels;
    final List<int> visible = [
      for (int i = 0; i < labels.length; i++)
        if (_matches(labels[i])) i,
    ];

    if (visible.isEmpty) return const _NoMatches();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.SM8),
      itemCount: visible.length,
      itemBuilder: (context, index) => _optionRow(visible[index]),
    );
  }

  /// Options are addressed by their index in the enum rather than by label, so
  /// a reworded string cannot make a tap select the wrong value.
  Widget _optionRow(int optionIndex) {
    switch (_activeSection) {
      case _Section.countStatus:
        final StockCountFilter option = StockCountFilter.values[optionIndex];
        return _OptionRow(
          label: option.label,
          isSelected: _draft.filter == option,
          onTap: () => setState(() => _draft = _draft.copyWith(filter: option)),
        );
      case _Section.sort:
        final StockSort option = StockSort.values[optionIndex];
        return _OptionRow(
          label: option.label,
          isSelected: _draft.sort == option,
          onTap: () => setState(() => _draft = _draft.copyWith(sort: option)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return DismissKeyboard(
      child: SizedBox(
        height: media.size.height * AppSizes.FILTER_SHEET_HEIGHT,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.SMD12),
            Container(
              width: AppSizes.CLIENT_SHEET_HANDLE_WIDTH,
              height: AppSizes.CLIENT_SHEET_HANDLE_HEIGHT,
              decoration: BoxDecoration(
                color: AppColors.BORDER_STRONG,
                borderRadius: BorderRadius.circular(AppRadius.FULL),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.LG24,
                AppSpacing.MD16,
                AppSpacing.SM8,
                AppSpacing.SMD12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.STOCK_FILTER_TITLE,
                      style: AppTypography.headingSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: AppSizes.ICON_LG,
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
              child: _SearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.BORDER),
                  borderRadius: BorderRadius.circular(AppRadius.SEGMENT),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CategoryRail(
                      activeSection: _activeSection,
                      activeCountFor: _activeCountFor,
                      onSelect: (section) =>
                          setState(() => _activeSection = section),
                    ),
                    Container(
                      width: AppSizes.HAIRLINE,
                      color: AppColors.HAIRLINE,
                    ),
                    Expanded(child: _buildOptions()),
                  ],
                ),
              ),
            ),
            _Footer(
              onClear: _clear,
              onApply: () => Navigator.of(context).pop(_draft),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section names down the left, with a dot wherever that section holds something
/// other than its default.
class _CategoryRail extends StatelessWidget {
  final _Section activeSection;
  final int Function(_Section) activeCountFor;
  final ValueChanged<_Section> onSelect;

  const _CategoryRail({
    required this.activeSection,
    required this.activeCountFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.FILTER_RAIL_WIDTH,
      child: Container(
        color: AppColors.BACKGROUND,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _Section.values.length,
          itemBuilder: (context, index) {
            final _Section section = _Section.values[index];
            final bool isActive = section == activeSection;
            final int count = activeCountFor(section);

            return GestureDetector(
              onTap: () => onSelect(section),
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: isActive ? AppColors.SURFACE : AppColors.TRANSPARENT,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.MD16),
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.FILTER_RAIL_ACTIVE_BAR,
                      height: AppSpacing.LG24,
                      color: isActive
                          ? AppColors.PRIMARY
                          : AppColors.TRANSPARENT,
                    ),
                    const SizedBox(width: AppSpacing.SMD12),
                    Expanded(
                      child: Text(
                        section.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: isActive
                            ? AppTypography.labelMedium.copyWith(
                                color: AppColors.PRIMARY,
                              )
                            : AppTypography.bodySmall.copyWith(
                                color: AppColors.TEXT_PRIMARY,
                              ),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: AppSpacing.XS4),
                      Container(
                        width: AppSizes.CLIENT_STATUS_DOT,
                        height: AppSizes.CLIENT_STATUS_DOT,
                        decoration: const BoxDecoration(
                          color: AppColors.PRIMARY,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.SM8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A single-select row: label plus a rounded selection box, matching the option
/// rows on the app's other filter sheets.
class _OptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: isSelected
                    ? AppTypography.labelMedium
                    : AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.SM8),
            Container(
              width: AppSizes.FILTER_CHECKBOX,
              height: AppSizes.FILTER_CHECKBOX,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.PRIMARY : AppColors.SURFACE,
                border: Border.all(
                  color: isSelected ? AppColors.PRIMARY : AppColors.BORDER,
                  width: AppSizes.BORDER_MEDIUM,
                ),
                borderRadius: BorderRadius.circular(AppRadius.FULL),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: AppSizes.CLIENT_CHIP_ICON,
                      color: AppColors.TEXT_ON_PRIMARY,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.bodyMedium,
      cursorColor: AppColors.PRIMARY,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: AppStrings.CLIENTS_SEARCH_FILTERS,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.TEXT_DISABLED,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: AppSizes.ICON_LG,
          color: AppColors.TEXT_SECONDARY,
        ),
        filled: true,
        fillColor: AppColors.SURFACE,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.MD16,
          vertical: AppSpacing.SMD12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
          borderSide: const BorderSide(color: AppColors.BORDER),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
          borderSide: const BorderSide(color: AppColors.BORDER),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
          borderSide: const BorderSide(
            color: AppColors.BORDER_FOCUSED,
            width: AppSizes.BORDER_MEDIUM,
          ),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Text(
          AppStrings.CLIENTS_NO_FILTER_MATCH,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onClear;
  final VoidCallback onApply;

  const _Footer({required this.onClear, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: const BoxDecoration(
        color: AppColors.SURFACE,
        border: Border(top: BorderSide(color: AppColors.HAIRLINE)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    AppSizes.BUTTON_MIN_WIDTH,
                    AppSizes.BUTTON_HEIGHT,
                  ),
                  side: const BorderSide(color: AppColors.PRIMARY),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.CHIP),
                  ),
                ),
                child: Text(
                  AppStrings.CLIENTS_CLEAR_ALL,
                  style: AppTypography.button.copyWith(
                    color: AppColors.PRIMARY,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.SMD12),
            Expanded(
              child: PrimaryButton(
                label: AppStrings.STOCK_FILTER_APPLY,
                onPressed: onApply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
