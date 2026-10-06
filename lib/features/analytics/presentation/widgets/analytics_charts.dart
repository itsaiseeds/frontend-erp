import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../orders/data/models/order_status.dart';
import '../../data/models/analytics_summary.dart';

/// The colour a status is already shown in elsewhere, so a slice here and a
/// badge on an order card mean the same thing.
Color colorForStatus(String key) {
  switch (OrderStatusX.fromRaw(key)) {
    case OrderStatus.booked:
      return AppColors.STATUS_BOOKED;
    case OrderStatus.underReview:
      return AppColors.STATUS_UNDER_REVIEW;
    case OrderStatus.confirmed:
      return AppColors.STATUS_CONFIRMED;
    case OrderStatus.dispatched:
      return AppColors.STATUS_DISPATCHED;
    case OrderStatus.delivered:
      return AppColors.STATUS_DELIVERED;
    case OrderStatus.rejected:
      return AppColors.STATUS_REJECTED;
    case OrderStatus.onHold:
      return AppColors.STATUS_ON_HOLD;
    case OrderStatus.unknown:
      return AppColors.TEXT_SECONDARY;
  }
}

/// A donut of order statuses with the total in the middle.
///
/// The hole carries the headline number so the chart answers "how many?"
/// and "made up of what?" in one glance, without a legend lookup.
class OrderStatusDonut extends StatelessWidget {
  final OrderBreakdown breakdown;

  const OrderStatusDonut({super.key, required this.breakdown});

  static const double _size = 168;
  static const double _ring = 26;

  @override
  Widget build(BuildContext context) {
    final List<StatusCount> slices = breakdown.presentBuckets;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: (_size / 2) - _ring,
                  startDegreeOffset: -90,
                  sections: [
                    for (final StatusCount slice in slices)
                      PieChartSectionData(
                        value: slice.count.toDouble(),
                        color: colorForStatus(slice.key),
                        radius: _ring,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${breakdown.total}',
                    style: AppTypography.headingSmall,
                  ),
                  Text(
                    AppStrings.ANALYTICS_ORDERS_TITLE.toLowerCase(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.MD16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final StatusCount slice in slices)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.SM8),
                  child: _LegendRow(
                    color: colorForStatus(slice.key),
                    label: slice.label,
                    count: slice.count,
                    total: breakdown.total,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = total == 0 ? 0 : ((count / total) * 100).round();

    return Row(
      children: [
        Container(
          width: AppSpacing.SM8,
          height: AppSpacing.SM8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
        Text('$count', style: AppTypography.labelStrong),
        const SizedBox(width: AppSpacing.XS4),
        SizedBox(
          width: 38,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_DISABLED,
            ),
          ),
        ),
      ],
    );
  }
}

/// Horizontal bars of the kilograms booked per product, heaviest first.
///
/// Bars rather than a second pie: product names need room to read, and
/// comparing lengths along a shared baseline beats comparing angles.
class ProductWeightBars extends StatelessWidget {
  final List<ProductWeight> products;

  const ProductWeightBars({super.key, required this.products});

  /// Enough to show what is moving without turning the card into a list.
  static const int maxRows = 5;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Text(
        AppStrings.ANALYTICS_NO_PRODUCTS,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.TEXT_SECONDARY,
        ),
      );
    }

    final List<ProductWeight> rows = products.take(maxRows).toList();
    // The API sends these heaviest first, so the first row is the longest
    // bar and every other is measured against it.
    final double heaviest = rows.first.totalValue;

    // Only the statuses actually present across these rows, so the key
    // never lists a colour the bars do not use.
    final List<String> legendKeys = [
      for (final String key in OrderBreakdown.statusOrder)
        if (rows.any((row) => row.kgFor(key) > 0)) key,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ProductWeight row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.SMD12),
            child: _ProductBar(row: row, heaviest: heaviest),
          ),
        if (legendKeys.isNotEmpty) _StatusKey(statusKeys: legendKeys),
      ],
    );
  }
}

/// A colour key for the stacked bars above it.
class _StatusKey extends StatelessWidget {
  final List<String> statusKeys;

  const _StatusKey({required this.statusKeys});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.SMD12,
      runSpacing: AppSpacing.SM8,
      children: [
        for (final String key in statusKeys)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.SM8,
                height: AppSpacing.SM8,
                decoration: BoxDecoration(
                  color: colorForStatus(key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.XS4),
              Text(
                OrderStatusX.labelOf(OrderStatusX.fromRaw(key)),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.TEXT_SECONDARY,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ProductBar extends StatelessWidget {
  final ProductWeight row;
  final double heaviest;

  const _ProductBar({required this.row, required this.heaviest});

  /// Trailing zeros on a weight are noise on a phone: 40.000 reads as 40,
  /// while 1.500 keeps the half it needs.
  String get _weightLabel {
    final double value = row.totalValue;
    final String text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
    return '$text ${AppStrings.ANALYTICS_KG}';
  }

  @override
  Widget build(BuildContext context) {
    final double delivered = row.deliveredKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall,
              ),
            ),
            const SizedBox(width: AppSpacing.SM8),
            Text(_weightLabel, style: AppTypography.labelStrong),
          ],
        ),
        const SizedBox(height: AppSpacing.XS4),
        // Flex rather than a measured width: a LayoutBuilder here reports
        // the Column's constraints, which left the fill collapsed. Both rows
        // stretch, or a ColoredBox has no height of its own and paints
        // nothing however wide its flex makes it.
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.FULL),
          child: SizedBox(
            height: AppSpacing.SM8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _flexOf(row.totalValue),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final WeightSegment segment in row.segments)
                        Expanded(
                          flex: _flexOf(segment.kg),
                          child: ColoredBox(
                            color: colorForStatus(segment.key),
                          ),
                        ),
                      // Weight the split does not account for is still the
                      // product's: it reads as filled bar, in the booked
                      // tone, rather than a grey block that looks like the
                      // bar stopped short of its own total.
                      if (row.unattributedKg > 0)
                        Expanded(
                          flex: _flexOf(row.unattributedKg),
                          child: const ColoredBox(
                            color: AppColors.STATUS_BOOKED,
                          ),
                        ),
                    ],
                  ),
                ),
                if (heaviest > row.totalValue)
                  Expanded(
                    flex: _flexOf(heaviest - row.totalValue),
                    child: const ColoredBox(
                      color: AppColors.SURFACE_VARIANT,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (delivered > 0) ...[
          const SizedBox(height: AppSpacing.XS4),
          Text(
            '${_trim(delivered)} ${AppStrings.ANALYTICS_KG} '
            '${AppStrings.ANALYTICS_DELIVERED.toLowerCase()}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.SUCCESS,
            ),
          ),
        ],
      ],
    );
  }

  /// Expanded needs whole numbers, so grams become the unit. A segment
  /// never rounds to zero and vanishes from the bar.
  static int _flexOf(double kg) {
    final int grams = (kg * 1000).round();
    return grams < 1 ? 1 : grams;
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
}
