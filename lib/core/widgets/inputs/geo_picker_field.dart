import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../services/metadata_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../loaders/shimmer_block.dart';

class GeoPickerField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final bool Function(T a, T b) isSame;
  final ValueChanged<T> onSelected;
  final String? errorText;
  final bool enabled;
  final bool isRequired;
  final String? disabledHint;

  const GeoPickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.isSame,
    required this.onSelected,
    this.errorText,
    this.enabled = true,
    this.isRequired = false,
    this.disabledHint,
  });

  @override
  State<GeoPickerField<T>> createState() => _GeoPickerFieldState<T>();
}

class _GeoPickerFieldState<T> extends State<GeoPickerField<T>> {
  final LayerLink _link = LayerLink();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlay;
  String _query = '';

  /// A mouse press inside the panel blurs the field before the tap resolves.
  /// Tearing the overlay down on that blur would destroy the option before it
  /// is ever tapped, which is why the picker looked dead on web.
  bool _isPointerInPanel = false;

  @override
  void initState() {
    super.initState();
    _syncText();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant GeoPickerField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _syncText();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncText() {
    _controller.text = widget.value == null
        ? ''
        : widget.itemLabel(widget.value as T);
    _query = '';
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _controller.clear();
      _query = '';
      _showOverlay();
      return;
    }

    if (_isPointerInPanel) return;
    _removeOverlay();
    _syncText();
  }

  List<T> get _filtered {
    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return widget.items;
    return widget.items
        .where((item) => widget.itemLabel(item).toLowerCase().contains(needle))
        .toList(growable: false);
  }

  void _showOverlay() {
    _removeOverlay();

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    _overlay = OverlayEntry(
      builder: (context) => Positioned(
        // Anchored at the origin and moved by the follower: a Positioned with
        // no left/top is unconstrained, which leaves the panel painting in one
        // place while taps route to another.
        left: 0,
        top: 0,
        width: box.size.width,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, box.size.height + AppSpacing.XS4),
          child: Listener(
            onPointerDown: (_) => _isPointerInPanel = true,
            onPointerUp: (_) => _isPointerInPanel = false,
            onPointerCancel: (_) => _isPointerInPanel = false,
            child: _OptionsPanel<T>(
              items: _filtered,
              itemLabel: widget.itemLabel,
              isSelected: (item) =>
                  widget.value != null &&
                  widget.isSame(item, widget.value as T),
              onSelected: (item) {
                _isPointerInPanel = false;
                widget.onSelected(item);
                _removeOverlay();
                _focusNode.unfocus();
                _syncText();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _rebuildOverlay() {
    if (_overlay == null) return;
    _overlay!.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MetadataStatus>(
      valueListenable: MetadataService.instance.statusListenable,
      builder: (context, status, _) {
        final bool isLoading = status == MetadataStatus.loading;
        final bool hasError =
            widget.errorText != null && widget.errorText!.isNotEmpty;
        final bool canOpen =
            widget.enabled && !isLoading && widget.items.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                text: widget.label,
                style: AppTypography.labelStrong,
                children: widget.isRequired
                    ? [
                        TextSpan(
                          text: AppStrings.REQUIRED_MARKER,
                          style: AppTypography.labelStrong.copyWith(
                            color: AppColors.ERROR,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.SM8),
            CompositedTransformTarget(
              link: _link,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: canOpen,
                readOnly: !canOpen,
                style: AppTypography.bodyMedium,
                cursorColor: AppColors.PRIMARY,
                onChanged: (value) {
                  _query = value;
                  _rebuildOverlay();
                },
                decoration: InputDecoration(
                  hintText: _hintText(isLoading),
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.TEXT_DISABLED,
                  ),
                  filled: true,
                  fillColor: canOpen
                      ? AppColors.SURFACE
                      : AppColors.SURFACE_VARIANT,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.MD16,
                    vertical: AppSpacing.SMD12,
                  ),
                  suffixIcon: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.SM14),
                          child: ShimmerBlock(
                            width: AppSizes.ICON_XL,
                            height: AppSpacing.MD16,
                            radius: AppRadius.SM,
                          ),
                        )
                      : Icon(
                          _focusNode.hasFocus
                              ? Icons.search_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: AppSizes.ICON_MD,
                          color: AppColors.TEXT_SECONDARY,
                        ),
                  border: _border(
                    hasError ? AppColors.ERROR : AppColors.BORDER,
                  ),
                  enabledBorder: _border(
                    hasError ? AppColors.ERROR : AppColors.BORDER,
                  ),
                  disabledBorder: _border(AppColors.BORDER),
                  focusedBorder: _border(
                    hasError ? AppColors.ERROR : AppColors.BORDER_FOCUSED,
                    width: AppSizes.BORDER_MEDIUM,
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: AppSpacing.XS4),
              Text(
                widget.errorText!,
                style: AppTypography.caption.copyWith(color: AppColors.ERROR),
              ),
            ],
          ],
        );
      },
    );
  }

  String _hintText(bool isLoading) {
    if (isLoading) return AppStrings.LOADING;
    if (!widget.enabled && widget.disabledHint != null) {
      return widget.disabledHint!;
    }
    if (widget.items.isEmpty) return AppStrings.GEO_UNAVAILABLE;
    return widget.hint;
  }

  static OutlineInputBorder _border(
    Color color, {
    double width = AppSizes.BORDER_THIN,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.CHIP),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _OptionsPanel<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) itemLabel;
  final bool Function(T item) isSelected;
  final ValueChanged<T> onSelected;

  const _OptionsPanel({
    required this.items,
    required this.itemLabel,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.CHIP),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: AppSizes.GEO_DROPDOWN_MAX_HEIGHT,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.BORDER),
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
        ),
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.MD16),
                child: Text(
                  AppStrings.CLIENTS_NO_FILTER_MATCH,
                  style: AppTypography.bodySmall,
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final T item = items[index];
                  final bool selected = isSelected(item);

                  return InkWell(
                    onTap: () => onSelected(item),
                    child: Container(
                      color: selected
                          ? AppColors.PRIMARY_SURFACE
                          : AppColors.TRANSPARENT,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.MD16,
                        vertical: AppSpacing.SMD12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              itemLabel(item),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: selected
                                  ? AppTypography.labelMedium.copyWith(
                                      color: AppColors.PRIMARY,
                                    )
                                  : AppTypography.bodyMedium,
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_rounded,
                              size: AppSizes.ICON_MD,
                              color: AppColors.PRIMARY,
                            ),
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
