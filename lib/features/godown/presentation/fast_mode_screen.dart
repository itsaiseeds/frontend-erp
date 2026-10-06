import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/font_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_url_resolver.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import 'widgets/fast_mode_row.dart';

/// A full-screen, one-row-at-a-time counting flow -- Tinder-card `PageView`
/// paging plus a captive on-screen numeric keypad so the OS keyboard never
/// appears (no `TextField` anywhere; the digit display is a plain `Text`
/// driven by a local string buffer the keypad mutates).
///
/// Generic over bag stock and packet stock: both pass their packaging/pair
/// list as [rows] and get the entered count back through [onCountChanged] as
/// the user types, so a caller that shares its cubit via `BlocProvider.value`
/// when pushing this route keeps one source of truth with the table screen.
class FastModeScreen extends StatefulWidget {
  final String title;
  final String unitLabel;
  final List<FastModeRow> rows;
  final void Function(String key, int? count) onCountChanged;

  /// Commits the counts. Returning `false` leaves the user on the review page
  /// with their entries intact so a failed save is never a lost run.
  final Future<bool> Function() onSubmit;

  const FastModeScreen({
    super.key,
    required this.title,
    required this.unitLabel,
    required this.rows,
    required this.onCountChanged,
    required this.onSubmit,
  });

  static Future<void> push(
    BuildContext context, {
    required String title,
    required String unitLabel,
    required List<FastModeRow> rows,
    required void Function(String key, int? count) onCountChanged,
    required Future<bool> Function() onSubmit,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: FastModeScreen(
            title: title,
            unitLabel: unitLabel,
            rows: rows,
            onCountChanged: onCountChanged,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  @override
  State<FastModeScreen> createState() => _FastModeScreenState();
}

class _FastModeScreenState extends State<FastModeScreen> {
  static const int _maxDigits = 6;

  late final PageController _pageController;
  late final List<String> _buffers;

  /// Every index the `PageView` has ever settled on. A row the user has
  /// already seen and left empty is "skipped", not merely "pending" --
  /// pending is just every row's starting state, so only a visited-but-empty
  /// row earns the distinct progress-bar marker.
  late final Set<int> _visited;
  int _pageIndex = 0;
  bool _isSubmitting = false;

  /// The review table is the last page of the pager, so the counting pages stay
  /// at their original indices and the progress bar keeps counting products.
  int get _summaryIndex => widget.rows.length;

  int get _countedCount => _buffers.where((buffer) => buffer.isNotEmpty).length;

  int get _skippedCount => _buffers.where((buffer) => buffer.isEmpty).length;

  bool get _isOnSummary => _pageIndex == _summaryIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buffers = [
      for (final FastModeRow row in widget.rows)
        row.draftCount?.toString() ?? '',
    ];
    _visited = {0};
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isOnSummary) return;
    final String current = _buffers[_pageIndex];
    if (current.length >= _maxDigits) return;
    final String next = current == '0' ? digit : '$current$digit';
    setState(() => _buffers[_pageIndex] = next);
    _emit(next);
  }

  void _onBackspace() {
    if (_isOnSummary) return;
    final String current = _buffers[_pageIndex];
    if (current.isEmpty) return;
    final String next = current.substring(0, current.length - 1);
    setState(() => _buffers[_pageIndex] = next);
    _emit(next);
  }

  void _emit(String buffer) {
    final FastModeRow row = widget.rows[_pageIndex];
    widget.onCountChanged(
      row.key,
      buffer.isEmpty ? null : int.tryParse(buffer),
    );
  }

  void _jumpTo(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// The review table lives at the end of the pager, so tapping "Review" (or
  /// swiping past the last product) lands on it.
  void _openSummary() => _jumpTo(_summaryIndex);

  Future<void> _confirmUpdate() async {
    final int counted = _countedCount;
    if (counted == 0) {
      ToastUtils.showWarning(
        context,
        AppStrings.STOCK_UPDATE_CONFIRM_BODY_NONE,
      );
      return;
    }

    final int skipped = _skippedCount;
    final String body = skipped == 0
        ? '${AppStrings.STOCK_UPDATE_CONFIRM_BODY_ALL} $counted '
              '${widget.unitLabel}.'
        : '${AppStrings.STOCK_UPDATE_CONFIRM_BODY_COUNTED} $counted '
              '${widget.unitLabel}. $skipped '
              '${AppStrings.STOCK_UPDATE_CONFIRM_BODY_SKIPPED}';

    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.STOCK_UPDATE_CONFIRM_TITLE,
      body: body,
      confirmLabel: AppStrings.STOCK_UPDATE,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    final bool saved = await widget.onSubmit();
    if (!mounted) return;

    // A failed save must not close the review page -- the entries are the only
    // copy of this run, so the user stays put and can retry.
    setState(() => _isSubmitting = false);
    if (saved) Navigator.of(context).pop();
  }

  /// A row is skipped only once it has been seen *and* left behind empty.
  /// Excluding the page currently on screen stops a row being flagged the
  /// instant the user lands on it, before they have had the chance to type.
  bool _isSkipped(int index) =>
      _visited.contains(index) &&
      index != _pageIndex &&
      _buffers[index].isEmpty;

  /// Leaving the active row is what promotes it to "skipped", so the marker
  /// has to be recomputed whenever the page changes.
  void _markVisited(int index) {
    setState(() {
      _pageIndex = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.rows.length;

    return Scaffold(
      backgroundColor: AppColors.SURFACE,
      appBar: AppBar(
        backgroundColor: AppColors.SURFACE,
        surfaceTintColor: AppColors.TRANSPARENT,
        elevation: 0,
        leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: Text(
          _isOnSummary ? AppStrings.STOCK_SUMMARY_TITLE : widget.title,
          style: AppTypography.titleMedium,
        ),
        centerTitle: false,
        // While counting the action simply leaves; on the review page the same
        // slot becomes the commit, so there is never a second way to save.
        actions: [
          TextButton(
            // Locked while the save is in flight so a double tap cannot fire
            // two POST/PATCH pairs for the same run.
            onPressed: _isSubmitting
                ? null
                : total == 0
                ? () => Navigator.of(context).pop()
                : _isOnSummary
                ? _confirmUpdate
                : () => Navigator.of(context).pop(),
            child: _isSubmitting
                ? const SizedBox(
                    width: AppSizes.ICON_MD,
                    height: AppSizes.ICON_MD,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isOnSummary && total > 0
                        ? AppStrings.STOCK_UPDATE
                        : AppStrings.STOCK_FAST_MODE_DONE,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.PRIMARY,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.XS6),
        ],
      ),
      body: total == 0
          ? Center(
              child: Text(
                AppStrings.STOCK_NO_PACKAGINGS_TITLE,
                style: AppTypography.bodyMedium,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.MD16,
                    AppSpacing.SM8,
                    AppSpacing.MD16,
                    0,
                  ),
                  child: _isOnSummary
                      ? _SummaryCountLine(
                          counted: _countedCount,
                          skipped: _skippedCount,
                        )
                      : _ProgressBar(
                          current: _pageIndex,
                          total: total,
                          labels: [
                            for (final FastModeRow row in widget.rows)
                              row.title,
                          ],
                          isCounted: (index) => _buffers[index].isNotEmpty,
                          isSkipped: (index) => _isSkipped(index),
                          onTapSegment: _jumpTo,
                          onReview: _openSummary,
                        ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: total + 1,
                    onPageChanged: _markVisited,
                    itemBuilder: (context, index) {
                      if (index == _summaryIndex) {
                        return _SummaryTable(
                          rows: widget.rows,
                          buffers: _buffers,
                          unitLabel: widget.unitLabel,
                          onTapRow: _jumpTo,
                        );
                      }
                      return _FastModeCard(
                        row: widget.rows[index],
                        buffer: _buffers[index],
                        unitLabel: widget.unitLabel,
                      );
                    },
                  ),
                ),
                // The keypad is meaningless on the review page, so it steps
                // aside and gives the table the full height.
                if (!_isOnSummary)
                  _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom + AppSpacing.SM8,
                ),
              ],
            ),
    );
  }
}

/// Replaces the product progress bar on the review page, where the only
/// useful signal is how much of the run is actually going to be saved.
class _SummaryCountLine extends StatelessWidget {
  final int counted;
  final int skipped;

  const _SummaryCountLine({required this.counted, required this.skipped});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.XS6),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCount(
              icon: Icons.check_circle_rounded,
              iconColor: counted > 0
                  ? AppColors.SUCCESS
                  : AppColors.TEXT_DISABLED,
              label: '$counted ${AppStrings.STOCK_SUMMARY_COUNTED}',
            ),
          ),
          Expanded(
            child: _SummaryCount(
              icon: Icons.remove_circle_outline_rounded,
              iconColor: skipped > 0
                  ? AppColors.WARNING
                  : AppColors.TEXT_DISABLED,
              label: '$skipped ${AppStrings.STOCK_SUMMARY_MISSING}',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _SummaryCount({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppSizes.ICON_SM, color: iconColor),
        const SizedBox(width: AppSpacing.XS6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
      ],
    );
  }
}

/// One segment per row, tappable to jump straight to it. A counted row is
/// solid green, a skipped one (visited, still empty) carries a small pending
/// dot so it reads as "needs attention" rather than simply unfinished, and
/// everything else is a plain track -- not yet seen, nothing to flag.
class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final List<String> labels;
  final bool Function(int index) isCounted;
  final bool Function(int index) isSkipped;
  final ValueChanged<int> onTapSegment;
  final VoidCallback onReview;

  const _ProgressBar({
    required this.current,
    required this.total,
    required this.labels,
    required this.isCounted,
    required this.isSkipped,
    required this.onTapSegment,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final int skippedCount = [
      for (int i = 0; i < total; i++)
        if (isSkipped(i)) i,
    ].length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${current + 1} ${AppStrings.STOCK_FAST_MODE_PROGRESS_OF} $total',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
            const Spacer(),
            if (skippedCount > 0) ...[
              Icon(
                Icons.circle,
                size: AppSpacing.XXS2 * 2,
                color: AppColors.WARNING,
              ),
              const SizedBox(width: AppSpacing.XS4),
              Text(
                skippedCount == 1
                    ? AppStrings.STOCK_FAST_MODE_SKIPPED_ONE
                    : '$skippedCount ${AppStrings.STOCK_FAST_MODE_SKIPPED_MANY}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.WARNING,
                ),
              ),
              const SizedBox(width: AppSpacing.XS6),
            ],
            // Without this the review page is only reachable by swiping, which
            // is easy to miss and even easier to overshoot.
            GestureDetector(
              onTap: onReview,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.STOCK_SUMMARY_REVIEW,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.PRIMARY,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.ICON_MD,
                    color: AppColors.PRIMARY,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.XS6),
        SizedBox(
          height: AppSpacing.MD18,
          child: Row(
            children: [
              for (int i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.XXS2),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: i < labels.length ? labels[i] : '${i + 1}',
                    child: GestureDetector(
                      onTap: () => onTapSegment(i),
                      behavior: HitTestBehavior.opaque,
                      child: _ProgressSegment(
                        isCurrent: i == current,
                        isCounted: isCounted(i),
                        isSkipped: isSkipped(i),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (skippedCount > 0) ...[
          const SizedBox(height: AppSpacing.XS6),
          Text(
            AppStrings.STOCK_FAST_MODE_SKIPPED_HINT,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_TERTIARY,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final bool isCurrent;
  final bool isCounted;
  final bool isSkipped;

  const _ProgressSegment({
    required this.isCurrent,
    required this.isCounted,
    required this.isSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isCounted
        ? AppColors.PRIMARY
        : isSkipped
        ? AppColors.WARNING
        : AppColors.SURFACE_VARIANT;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: isCurrent ? AppSpacing.XS6 : AppSpacing.XS5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.FULL),
          border: isCurrent
              ? Border.all(
                  color: AppColors.TEXT_PRIMARY,
                  width: AppSizes.BORDER_THIN,
                )
              : null,
        ),
      ),
    );
  }
}

/// Final page of Fill Stock: the whole run at a glance before it is saved.
/// Two columns only -- product detail on the left, the count about to be
/// written on the right -- so it reads as the same table the user just filled.
class _SummaryTable extends StatelessWidget {
  final List<FastModeRow> rows;
  final List<String> buffers;
  final String unitLabel;
  final ValueChanged<int> onTapRow;

  const _SummaryTable({
    required this.rows,
    required this.buffers,
    required this.unitLabel,
    required this.onTapRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.SURFACE_VARIANT,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.MD16,
            vertical: AppSpacing.SMD12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.STOCK_TABLE_PRODUCT_LABEL,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.TEXT_TERTIARY,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              SizedBox(
                width: AppSizes.GODOWN_TABLE_COLUMN_NARROW,
                child: Text(
                  unitLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.TEXT_TERTIARY,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final String buffer = buffers[index];
              final bool isCounted = buffer.isNotEmpty;

              return Material(
                color: index.isEven
                    ? AppColors.SURFACE
                    : AppColors.BACKGROUND_TINTED,
                child: InkWell(
                  onTap: () => onTapRow(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.MD16,
                      vertical: AppSpacing.SMD12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rows[index].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium,
                              ),
                              if (rows[index].subtitle.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.XXS2),
                                Text(
                                  rows[index].subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.TEXT_TERTIARY,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.SMD12),
                        SizedBox(
                          width: AppSizes.GODOWN_TABLE_COLUMN_NARROW,
                          child: Text(
                            isCounted
                                ? buffer
                                : AppStrings.STOCK_SUMMARY_MISSING,
                            textAlign: TextAlign.center,
                            style: isCounted
                                ? AppTypography.titleMedium.copyWith(
                                    color: AppColors.PRIMARY,
                                  )
                                : AppTypography.bodySmall.copyWith(
                                    color: AppColors.TEXT_DISABLED,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FastModeCard extends StatelessWidget {
  final FastModeRow row;
  final String buffer;
  final String unitLabel;

  const _FastModeCard({
    required this.row,
    required this.buffer,
    required this.unitLabel,
  });

  /// The photo is the focal point of the card, so it takes the largest square
  /// that still leaves room for the info card and the count below it. Width
  /// and height are both consulted: a narrow phone caps it on width, a short
  /// one (landscape, or a small handset with the keypad open) on height.
  static const double _minImage = 120;
  static const double _maxImage = 280;
  static const double _widthShare = 0.7;

  /// Space the text needs regardless of the photo: the three spacers and the
  /// two line boxes under the count. The info card is deliberately not counted
  /// here -- [_maxInfoHeight] reserves its worst case. The scroll padding is
  /// excluded because [_minHeightFor] already subtracts it.
  static const double _chromeHeight =
      AppSpacing.MD16 + // photo to info card
      AppSpacing.LG24 + // info card to count
      AppSpacing.XS6 + // count to unit label
      58 + // the 48pt count's line box
      16; // unit label's line box

  /// Worst case for the info card: a name capped at two lines plus the
  /// packaging line. Reserving the worst case is what keeps a long product
  /// name from silently reintroducing a scrollbar on a short screen.
  static const double _maxInfoHeight = 72;

  /// The largest square that still leaves room for all the text. Derived from
  /// the real chrome rather than a fixed fraction of the viewport, so the card
  /// fits on a 900px handset and still uses the space on a tablet.
  static double _imageSizeFor(BoxConstraints constraints) {
    final double byWidth = constraints.maxWidth * _widthShare;
    final double byHeight =
        constraints.maxHeight - _chromeHeight - _maxInfoHeight;
    final double size = byWidth < byHeight ? byWidth : byHeight;
    if (size < _minImage) return _minImage;
    if (size > _maxImage) return _maxImage;
    return size;
  }

  /// The scroll view adds its vertical padding on top of the child, so the
  /// child's minimum height has to be the viewport minus that padding. Using
  /// the raw viewport here is what made the card overflow by exactly the
  /// padding on every screen.
  static double _minHeightFor(BoxConstraints constraints) =>
      constraints.maxHeight - AppSpacing.MD16 * 2;

  @override
  Widget build(BuildContext context) {
    final String display = buffer.isEmpty ? '0' : buffer;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.LG24,
          vertical: AppSpacing.MD16,
        ),
        // Centring inside the viewport on tall screens, scrolling on short
        // ones, so the photo always reads as the focal point of the page.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _minHeightFor(constraints)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ProductImage(
                imageUrl: row.imageUrl,
                size: _imageSizeFor(constraints),
              ),
              const SizedBox(height: AppSpacing.MD16),
              _InfoCard(row: row),
              const SizedBox(height: AppSpacing.LG24),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: AppTypography.display.copyWith(
                  fontSize: AppFontSizes.FONT_48,
                  color: buffer.isEmpty
                      ? AppColors.TEXT_DISABLED
                      : AppColors.PRIMARY,
                ),
                child: Text(display),
              ),
              const SizedBox(height: AppSpacing.XS6),
              Text(
                unitLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.TEXT_TERTIARY,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Product name and packaging detail as one centred line, kept tight so the
/// whole card fits without scrolling on a normal handset. The photo above it
/// carries the visual weight, so the text stays small.
class _InfoCard extends StatelessWidget {
  final FastModeRow row;

  const _InfoCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final String? subtitle = row.subtitle.isEmpty ? null : row.subtitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          row.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.XXS2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ],
      ],
    );
  }
}

/// The product photo the admin uploaded, same as every other product tile in
/// this app. Rendered bare -- no frame, no tinted panel behind it -- so the
/// picture itself is the focal point; only the corner radius is applied. The
/// icon tile is a fallback for a product with no image or a failed load.
class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _ProductImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final String resolved = ImageUrlResolver.resolve(imageUrl);

    if (resolved.isEmpty) return _FallbackTile(size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.XXL),
      child: Image.network(
        resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _FallbackTile(size: size),
      ),
    );
  }
}

class _FallbackTile extends StatelessWidget {
  final double size;

  const _FallbackTile({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.XXL),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.3,
        color: AppColors.PRIMARY,
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  const _Keypad({required this.onDigit, required this.onBackspace});

  static const List<String> _rows = ['123', '456', '789'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.LG24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final String row in _rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.SMD12),
              child: Row(
                children: [
                  for (final String digit in row.split(''))
                    Expanded(child: _KeypadButton.digit(digit, onDigit)),
                ],
              ),
            ),
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              Expanded(child: _KeypadButton.digit('0', onDigit)),
              Expanded(
                child: _KeypadButton.icon(
                  Icons.backspace_outlined,
                  onBackspace,
                  semanticLabel: AppStrings.STOCK_FAST_MODE_BACKSPACE,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;

  const _KeypadButton._({
    required this.child,
    required this.onTap,
    this.semanticLabel,
  });

  factory _KeypadButton.digit(String digit, void Function(String) onDigit) {
    return _KeypadButton._(
      child: Text(digit, style: AppTypography.headingSmall),
      onTap: () => onDigit(digit),
    );
  }

  factory _KeypadButton.icon(
    IconData icon,
    VoidCallback onTap, {
    String? semanticLabel,
  }) {
    return _KeypadButton._(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Icon(
        icon,
        size: AppSizes.ICON_LG,
        color: AppColors.TEXT_SECONDARY,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.XS6),
      child: Material(
        color: AppColors.SURFACE,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.BORDER),
          borderRadius: BorderRadius.circular(AppRadius.LG),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: AppColors.PRIMARY_SURFACE,
          highlightColor: AppColors.PRIMARY_SURFACE,
          child: Semantics(
            label: semanticLabel,
            button: true,
            child: SizedBox(
              height: AppSpacing.XXL56,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
