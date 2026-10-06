import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/models/farmer_visit.dart';
import '../data/models/field_trip.dart';
import 'farmer_visit_form_screen.dart';
import 'widgets/farmer_chip.dart';

/// One farmer in full: who they are, what they grow, what of ours they use.
///
/// The card in a list can only show a couple of chips before it stops being
/// scannable, so everything that does not fit there lives here.
class FarmerDetailScreen extends StatelessWidget {
  final FarmerVisit visit;

  /// The trip the visit belongs to. Editing is only offered while that
  /// trip is running, which is the same gate the endpoint enforces.
  final FieldTrip? trip;

  const FarmerDetailScreen({super.key, required this.visit, this.trip});

  /// Resolves true when the farmer was changed, so the caller can refresh.
  static Future<bool?> push(
    BuildContext context, {
    required FarmerVisit visit,
    FieldTrip? trip,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FarmerDetailScreen(visit: visit, trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          AppStrings.FARMER_DETAIL_TITLE,
          style: AppTypography.titleMedium,
        ),
        actions: [
          if (trip != null && trip!.canRecordFarmer)
            IconButton(
              tooltip: AppStrings.FARMER_VISIT_EDIT,
              onPressed: () async {
                final bool? saved = await FarmerVisitFormScreen.push(
                  context,
                  trip: trip!,
                  existing: visit,
                );
                if ((saved ?? false) && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: AppSizes.ICON_LG,
                color: AppColors.PRIMARY,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.MD16),
        children: [
          _Identity(visit: visit),
          const SizedBox(height: AppSpacing.SMD12),
          _Facts(visit: visit),
          const SizedBox(height: AppSpacing.SMD12),
          _ChipSection(
            icon: Icons.grass_outlined,
            title: AppStrings.FARMER_DETAIL_CROPS,
            count: visit.crops.length,
            chips: [
              for (final FarmerCrop crop in visit.crops)
                FarmerChip(label: crop.name, kind: FarmerChipKind.crop),
            ],
            emptyLabel: null,
          ),
          const SizedBox(height: AppSpacing.SMD12),
          _ChipSection(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.FARMER_DETAIL_PRODUCTS,
            count: visit.products.length,
            chips: [
              for (final FarmerProduct product in visit.products)
                FarmerChip(label: product.name, kind: FarmerChipKind.product),
            ],
            emptyLabel: AppStrings.FARMER_DETAIL_NO_PRODUCTS,
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final FarmerVisit visit;

  const _Identity({required this.visit});

  @override
  Widget build(BuildContext context) {
    final String initial = visit.farmerName.trim().isEmpty
        ? '?'
        : visit.farmerName.trim()[0].toUpperCase();

    return _Card(
      child: Row(
        children: [
          Container(
            width: AppSizes.FARMER_AVATAR,
            height: AppSizes.FARMER_AVATAR,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.PRIMARY_SURFACE,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.PRIMARY,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(visit.farmerName, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.XXS2),
                Text(
                  visit.contactNumber,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final FarmerVisit visit;

  const _Facts({required this.visit});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            label: AppStrings.FARMER_DETAIL_VILLAGE,
            value: visit.village,
          ),
          const _Separator(),
          _Row(
            label: AppStrings.FARMER_DETAIL_LAND,
            value: '${visit.landAreaBigha} ${AppStrings.FARMER_VISIT_BIGHA}',
          ),
          const _Separator(),
          _Row(
            label: AppStrings.FARMER_DETAIL_RECORDED,
            value: DateFormatter.dayTimeFull(visit.createdAt),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final List<Widget> chips;
  final String? emptyLabel;

  const _ChipSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.chips,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.ICON_LG, color: AppColors.PRIMARY),
              const SizedBox(width: AppSpacing.SM8),
              Expanded(child: Text(title, style: AppTypography.labelStrong)),
              if (count > 0)
                Text(
                  '$count',
                  style: AppTypography.labelStrong.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.SMD12),
          if (chips.isEmpty)
            Text(
              emptyLabel ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_DISABLED,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.SM8,
              runSpacing: AppSpacing.SM8,
              children: chips,
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.XL),
        border: Border.all(color: AppColors.BORDER),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.SM8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Expanded(
            child: Text(
              value.trim().isEmpty ? AppStrings.ORDER_NO_DATE : value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.BORDER);
  }
}
