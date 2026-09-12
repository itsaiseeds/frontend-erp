import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../data/models/client_filter.dart';
import '../../data/models/clients_query.dart';

class ClientsFilterSheet extends StatefulWidget {
  final List<ClientFilter> filters;
  final List<ClientSort> sorts;
  final ClientsQuery query;

  const ClientsFilterSheet({
    super.key,
    required this.filters,
    required this.sorts,
    required this.query,
  });

  static Future<ClientsQuery?> show(
    BuildContext context, {
    required List<ClientFilter> filters,
    required List<ClientSort> sorts,
    required ClientsQuery query,
  }) {
    return showModalBottomSheet<ClientsQuery>(
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
      builder: (_) =>
          ClientsFilterSheet(filters: filters, sorts: sorts, query: query),
    );
  }

  @override
  State<ClientsFilterSheet> createState() => _ClientsFilterSheetState();
}

class _ClientsFilterSheetState extends State<ClientsFilterSheet> {
  static const String _sortSectionKey = '__sort__';

  late ClientsQuery _draft;
  late final TextEditingController _searchController;

  String _activeSection = '';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _draft = widget.query;
    _searchController = TextEditingController();
    _activeSection = _sections.isEmpty ? '' : _sections.first.key;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Section> get _sections {
    final List<_Section> sections = widget.filters
        .where((filter) => filter.kind != FilterKind.unsupported)
        .map(
          (filter) => _Section(
            key: filter.key,
            title: _titleFor(filter.key),
            filter: filter,
          ),
        )
        .toList();

    if (widget.sorts.isNotEmpty) {
      sections.add(
        _Section(key: _sortSectionKey, title: AppStrings.CLIENTS_SORT),
      );
    }

    return sections;
  }

  int _activeCountFor(_Section section) {
    if (section.key == _sortSectionKey) return _draft.sort == null ? 0 : 1;
    final ClientFilter filter = section.filter!;
    if (filter.kind == FilterKind.datetimeRange) {
      return _draft.rangeFor(filter.key).isEmpty ? 0 : 1;
    }
    return _draft.valuesFor(filter.key).length;
  }

  void _toggleOption(String key, String value) {
    final Set<String> current = Set.of(_draft.valuesFor(key));
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    setState(() => _draft = _draft.withSelection(key, current));
  }

  Future<void> _pickRange(ClientFilter filter) async {
    final DateRange current = _draft.rangeFor(filter.key);
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: current.from != null && current.to != null
          ? DateTimeRange(start: current.from!, end: current.to!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.PRIMARY,
            onPrimary: AppColors.TEXT_ON_PRIMARY,
            primaryContainer: AppColors.PRIMARY.withValues(
              alpha: AppSizes.RANGE_FILL_OPACITY,
            ),
            onPrimaryContainer: AppColors.PRIMARY_DARK,
            surface: AppColors.SURFACE,
            onSurface: AppColors.TEXT_PRIMARY,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.SURFACE,
            headerBackgroundColor: AppColors.PRIMARY,
            headerForegroundColor: AppColors.TEXT_ON_PRIMARY,
            rangeSelectionBackgroundColor: AppColors.PRIMARY.withValues(
              alpha: AppSizes.RANGE_FILL_OPACITY,
            ),
            rangeSelectionOverlayColor: WidgetStatePropertyAll(
              AppColors.PRIMARY.withValues(
                alpha: AppSizes.RANGE_OVERLAY_OPACITY,
              ),
            ),
            todayBorder: const BorderSide(color: AppColors.PRIMARY),
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      _draft = _draft.withRange(
        filter.key,
        DateRange(
          from: picked.start,
          to: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        ),
      );
    });
  }

  bool _matchesSearch(String label) {
    final String needle = _search.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return label.toLowerCase().contains(needle);
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final List<_Section> sections = _sections;

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
                      AppStrings.CLIENTS_FILTERS,
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
                      sections: sections,
                      activeKey: _activeSection,
                      activeCountFor: _activeCountFor,
                      onSelect: (key) => setState(() => _activeSection = key),
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
              onClear: () => setState(() {
                _draft = const ClientsQuery();
                _searchController.clear();
                _search = '';
              }),
              onApply: () => Navigator.of(context).pop(_draft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    if (_activeSection == _sortSectionKey) return _buildSortOptions();

    final _Section? section = _sections
        .where((entry) => entry.key == _activeSection)
        .firstOrNull;

    if (section?.filter == null) return const SizedBox.shrink();

    final ClientFilter filter = section!.filter!;

    if (filter.kind == FilterKind.datetimeRange) {
      return _buildRangeOption(filter);
    }

    final List<FilterOption> options = filter.options
        .where((option) => _matchesSearch(option.label))
        .toList();

    if (options.isEmpty) return const _NoMatches();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.SM8),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final FilterOption option = options[index];
        return _OptionRow(
          label: option.label,
          isSelected: _draft.valuesFor(filter.key).contains(option.value),
          onTap: () => _toggleOption(filter.key, option.value),
        );
      },
    );
  }

  Widget _buildRangeOption(ClientFilter filter) {
    final DateRange range = _draft.rangeFor(filter.key);
    final bool hasRange = !range.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: hasRange ? AppColors.PRIMARY_SURFACE : AppColors.SURFACE,
            borderRadius: BorderRadius.circular(AppRadius.CHIP),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _pickRange(filter),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.SMD12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasRange ? AppColors.PRIMARY : AppColors.BORDER,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.CHIP),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: AppSizes.ICON_MD,
                      color: hasRange
                          ? AppColors.PRIMARY
                          : AppColors.TEXT_SECONDARY,
                    ),
                    const SizedBox(width: AppSpacing.SM8),
                    Expanded(
                      child: Text(
                        hasRange
                            ? '${DateFormat.yMMMd().format(range.from!)} — ${DateFormat.yMMMd().format(range.to!)}'
                            : AppStrings.CLIENTS_PICK_RANGE,
                        maxLines: 2,
                        style: AppTypography.bodySmall.copyWith(
                          color: hasRange
                              ? AppColors.PRIMARY
                              : AppColors.TEXT_DISABLED,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasRange) ...[
            const SizedBox(height: AppSpacing.SMD12),
            GestureDetector(
              onTap: () => setState(
                () => _draft = _draft.withRange(filter.key, const DateRange()),
              ),
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.CLIENTS_CLEAR_DATES,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.ERROR,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    final List<ClientSort> sorts = widget.sorts
        .where((sort) => _matchesSearch(_titleFor(sort.key)))
        .toList();

    if (sorts.isEmpty) return const _NoMatches();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.SM8),
      children: [
        for (final ClientSort sort in sorts)
          _OptionRow(
            label: _titleFor(sort.key),
            isSelected: _draft.sort == sort.key,
            isRadio: true,
            onTap: () => setState(() {
              _draft = _draft.sort == sort.key
                  ? _draft.copyWith(clearSort: true)
                  : _draft.copyWith(sort: sort.key);
            }),
          ),
        if (_draft.sort != null) ...[
          const Divider(height: AppSizes.HAIRLINE, color: AppColors.HAIRLINE),
          _OptionRow(
            label: AppStrings.CLIENTS_SORT_NEWEST,
            isSelected: _draft.descending,
            isRadio: true,
            onTap: () =>
                setState(() => _draft = _draft.copyWith(descending: true)),
          ),
          _OptionRow(
            label: AppStrings.CLIENTS_SORT_OLDEST,
            isSelected: !_draft.descending,
            isRadio: true,
            onTap: () =>
                setState(() => _draft = _draft.copyWith(descending: false)),
          ),
        ],
      ],
    );
  }

  static String _titleFor(String key) {
    final String spaced = key.replaceAll('_id', '').replaceAll('_', ' ');
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class _Section {
  final String key;
  final String title;
  final ClientFilter? filter;

  const _Section({required this.key, required this.title, this.filter});
}

class _CategoryRail extends StatelessWidget {
  final List<_Section> sections;
  final String activeKey;
  final int Function(_Section) activeCountFor;
  final ValueChanged<String> onSelect;

  const _CategoryRail({
    required this.sections,
    required this.activeKey,
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
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final _Section section = sections[index];
            final bool isActive = section.key == activeKey;
            final int count = activeCountFor(section);

            return GestureDetector(
              onTap: () => onSelect(section.key),
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

class _OptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isRadio;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isRadio = false,
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
                borderRadius: BorderRadius.circular(
                  isRadio ? AppRadius.FULL : AppRadius.SM,
                ),
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
                label: AppStrings.CLIENTS_APPLY,
                onPressed: onApply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
