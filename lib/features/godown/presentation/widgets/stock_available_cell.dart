import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Read-only "Available" figure for a stock row: the second column of the
/// bag/packet stock tables. It shows the live position rather than an editable
/// box, because entering a count happens in the Fill Stock flow. A lot that has
/// not been counted yet has no position, so it shows a dash rather than a
/// misleading zero.
///
/// The column is labelled once by the table header, so this renders the bare
/// figure -- repeating "Available" on every row is what a card looks like, not
/// a table.
class StockAvailableCell extends StatelessWidget {
  final int? available;

  const StockAvailableCell({super.key, required this.available});

  @override
  Widget build(BuildContext context) {
    final int? value = available;

    return SizedBox(
      width: AppSizes.GODOWN_TABLE_COLUMN_NARROW,
      child: Text(
        value == null ? AppStrings.STOCK_AVAILABLE_UNKNOWN : '$value',
        textAlign: TextAlign.center,
        style: AppTypography.titleMedium.copyWith(
          color: value == null ? AppColors.TEXT_DISABLED : AppColors.PRIMARY,
        ),
      ),
    );
  }
}
