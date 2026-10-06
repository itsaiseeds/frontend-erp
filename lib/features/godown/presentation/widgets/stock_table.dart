import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'stock_available_cell.dart';

/// One row of the stock table, decoupled from the bag/packet draft-line models
/// so both screens render through exactly the same table.
class StockTableEntry {
  final String title;
  final String subtitle;
  final int? available;

  const StockTableEntry({
    required this.title,
    required this.subtitle,
    required this.available,
  });
}

/// A real two-column table -- a fixed header row above the data -- rather than
/// the card stack this replaces. The whole row is a tap target into Fill Stock,
/// so counting always happens in one place.
class StockTable extends StatelessWidget {
  final List<StockTableEntry> entries;
  final VoidCallback onRowTap;

  const StockTable({super.key, required this.entries, required this.onRowTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderRow(),
        for (int i = 0; i < entries.length; i++)
          _DataRow(entry: entries[i], isEven: i.isEven, onTap: onRowTap),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(width: AppSpacing.SMD12),
          SizedBox(
            width: AppSizes.GODOWN_TABLE_COLUMN_NARROW,
            child: Text(
              AppStrings.STOCK_AVAILABLE_LABEL,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.TEXT_TERTIARY,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final StockTableEntry entry;
  final bool isEven;
  final VoidCallback onTap;

  const _DataRow({
    required this.entry,
    required this.isEven,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEven ? AppColors.SURFACE : AppColors.BACKGROUND_TINTED,
      child: InkWell(
        onTap: onTap,
        child: Container(
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
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                    if (entry.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.XXS2),
                      Text(
                        entry.subtitle,
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
              StockAvailableCell(available: entry.available),
            ],
          ),
        ),
      ),
    );
  }
}
