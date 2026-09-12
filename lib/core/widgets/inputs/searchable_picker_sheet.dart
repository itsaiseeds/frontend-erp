import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class PickerResult<T> {
  final T? value;

  const PickerResult.value(this.value);

  const PickerResult.all() : value = null;

  bool get isAll => value == null;
}

class SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<T> items;
  final String Function(T item) itemLabel;
  final bool Function(T item)? isSelected;
  final IconData itemIcon;
  final String? allOptionLabel;
  final bool isAllSelected;

  const SearchablePickerSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.items,
    required this.itemLabel,
    this.isSelected,
    this.itemIcon = Icons.location_city_outlined,
    this.allOptionLabel,
    this.isAllSelected = false,
  });

  static Future<PickerResult<T>?> show<T>(
    BuildContext context, {
    required String title,
    required String searchHint,
    required List<T> items,
    required String Function(T item) itemLabel,
    bool Function(T item)? isSelected,
    IconData itemIcon = Icons.location_city_outlined,
    String? allOptionLabel,
    bool isAllSelected = false,
  }) {
    return showModalBottomSheet<PickerResult<T>>(
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
      builder: (_) => SearchablePickerSheet<T>(
        title: title,
        searchHint: searchHint,
        items: items,
        itemLabel: itemLabel,
        isSelected: isSelected,
        itemIcon: itemIcon,
        allOptionLabel: allOptionLabel,
        isAllSelected: isAllSelected,
      ),
    );
  }

  @override
  State<SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<SearchablePickerSheet<T>> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return widget.items;
    return widget.items
        .where((item) => widget.itemLabel(item).toLowerCase().contains(needle))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final List<T> items = _filtered;
    final bool hasAllOption = widget.allOptionLabel != null;

    final MediaQueryData media = MediaQuery.of(context);
    final double available = media.size.height - media.viewInsets.bottom;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: available * AppSizes.CLIENT_SHEET_MAX_HEIGHT,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        widget.title,
                        style: AppTypography.titleMedium,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.LG24,
                ),
                child: TextField(
                  controller: _controller,
                  style: AppTypography.bodyMedium,
                  cursorColor: AppColors.PRIMARY,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.TEXT_DISABLED,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: AppSizes.ICON_LG,
                      color: AppColors.TEXT_SECONDARY,
                    ),
                    filled: true,
                    fillColor: AppColors.SURFACE_VARIANT,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.MD16,
                      vertical: AppSpacing.SMD12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.LG),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.LG),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.LG),
                      borderSide: const BorderSide(
                        color: AppColors.BORDER_FOCUSED,
                        width: AppSizes.BORDER_MEDIUM,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.SM8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSpacing.MD16),
                  itemCount: items.length + (hasAllOption ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (hasAllOption && index == 0) {
                      return _PickerTile(
                        label: widget.allOptionLabel!,
                        icon: widget.itemIcon,
                        isSelected: widget.isAllSelected,
                        onTap: () =>
                            Navigator.of(context).pop(PickerResult<T>.all()),
                      );
                    }

                    final T item = items[index - (hasAllOption ? 1 : 0)];
                    return _PickerTile(
                      label: widget.itemLabel(item),
                      icon: widget.itemIcon,
                      isSelected: widget.isSelected?.call(item) ?? false,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(PickerResult<T>.value(item)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.LG24,
          vertical: AppSpacing.SM14,
        ),
        color: isSelected ? AppColors.PRIMARY_SURFACE : AppColors.TRANSPARENT,
        child: Row(
          children: [
            Icon(
              icon,
              size: AppSizes.ICON_MD,
              color: isSelected ? AppColors.PRIMARY : AppColors.TEXT_SECONDARY,
            ),
            const SizedBox(width: AppSpacing.SMD12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: isSelected
                    ? AppTypography.labelMedium.copyWith(
                        color: AppColors.PRIMARY,
                      )
                    : AppTypography.bodyMedium,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: AppSizes.ICON_MD,
                color: AppColors.PRIMARY,
              ),
          ],
        ),
      ),
    );
  }
}
