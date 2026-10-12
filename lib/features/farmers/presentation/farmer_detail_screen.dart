import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../field_trips/data/models/farmer_visit.dart';
import '../../field_trips/presentation/widgets/farmer_chip.dart';
import '../data/farmers_repository.dart';
import 'farmer_form_screen.dart';

/// One directly-recorded farmer in full, with edit and delete -- both always
/// available here, unlike the trip-scoped [FarmerDetailScreen] which gates
/// editing on the meeting still being open and never offers delete.
class FarmerDetailScreen extends StatefulWidget {
  final FarmerVisit farmer;

  const FarmerDetailScreen({super.key, required this.farmer});

  /// Resolves true when the farmer was changed or deleted, so the caller
  /// can refresh its list.
  static Future<bool?> push(BuildContext context, {required FarmerVisit farmer}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FarmerDetailScreen(farmer: farmer),
      ),
    );
  }

  @override
  State<FarmerDetailScreen> createState() => _FarmerDetailScreenState();
}

class _FarmerDetailScreenState extends State<FarmerDetailScreen> {
  late final FarmerVisit _farmer = widget.farmer;
  bool _isDeleting = false;

  late final FarmersRepository _repository = FarmersRepository(
    apiClient: context.read<ApiClient>(),
  );

  Future<void> _edit() async {
    final bool? saved = await FarmerFormScreen.push(
      context,
      existing: _farmer,
    );
    if ((saved ?? false) && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.FARMER_RECORD_DELETE_CONFIRM_TITLE,
      body: AppStrings.FARMER_RECORD_DELETE_CONFIRM_BODY,
      confirmLabel: AppStrings.FARMER_RECORD_DELETE,
      confirmColor: AppColors.ERROR,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _repository.deleteFarmer(_farmer.publicId);
      if (!mounted) return;
      ToastUtils.showSuccess(context, AppStrings.FARMER_RECORD_DELETED);
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ToastUtils.showError(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FarmerVisit farmer = _farmer;

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
          IconButton(
            tooltip: AppStrings.FARMER_VISIT_EDIT,
            onPressed: _isDeleting ? null : _edit,
            icon: const Icon(
              Icons.edit_outlined,
              size: AppSizes.ICON_LG,
              color: AppColors.PRIMARY,
            ),
          ),
          IconButton(
            tooltip: AppStrings.FARMER_RECORD_DELETE,
            onPressed: _isDeleting ? null : _delete,
            icon: _isDeleting
                ? const SizedBox(
                    width: AppSizes.ICON_MD,
                    height: AppSizes.ICON_MD,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.BORDER_MEDIUM,
                      color: AppColors.ERROR,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    size: AppSizes.ICON_LG,
                    color: AppColors.ERROR,
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.MD16),
        children: [
          _Identity(farmer: farmer),
          const SizedBox(height: AppSpacing.SMD12),
          _Facts(farmer: farmer),
          const SizedBox(height: AppSpacing.SMD12),
          _ChipSection(
            icon: Icons.grass_outlined,
            title: AppStrings.FARMER_DETAIL_CROPS,
            count: farmer.crops.length,
            chips: [
              for (final FarmerCrop crop in farmer.crops)
                FarmerChip(label: crop.name, kind: FarmerChipKind.crop),
            ],
            emptyLabel: null,
          ),
          const SizedBox(height: AppSpacing.SMD12),
          _ChipSection(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.FARMER_DETAIL_PRODUCTS,
            count: farmer.products.length,
            chips: [
              for (final FarmerProduct product in farmer.products)
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
  final FarmerVisit farmer;

  const _Identity({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final String initial = farmer.farmerName.trim().isEmpty
        ? '?'
        : farmer.farmerName.trim()[0].toUpperCase();

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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        farmer.farmerName,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    if (farmer.isLead) ...[
                      const SizedBox(width: AppSpacing.SM8),
                      _LeadChip(),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.XXS2),
                Text(
                  farmer.contactNumber,
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

class _LeadChip extends StatelessWidget {
  const _LeadChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.WARNING_LIGHT,
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Text(
        AppStrings.FARMER_LEAD_BADGE,
        style: AppTypography.labelSmall.copyWith(color: AppColors.WARNING),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final FarmerVisit farmer;

  const _Facts({required this.farmer});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            label: AppStrings.FARMER_DETAIL_VILLAGE,
            value: farmer.village,
          ),
          const _Separator(),
          _Row(
            label: AppStrings.FARMER_DETAIL_LAND,
            value: '${farmer.landAreaBigha} ${AppStrings.FARMER_VISIT_BIGHA}',
          ),
          const _Separator(),
          _Row(
            label: AppStrings.FARMER_DETAIL_RECORDED,
            value: DateFormatter.dayTimeFull(farmer.createdAt),
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
