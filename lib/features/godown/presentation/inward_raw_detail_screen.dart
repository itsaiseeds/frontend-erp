import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../data/models/inward_raw_material.dart';
import '../data/models/inward_raw_status.dart';
import 'bloc/inward_raw_cubit.dart';
import 'bloc/inward_raw_state.dart';
import 'widgets/inward_raw_status_badge.dart';

/// One raw-material lot: its plan, dates and current status.
///
/// Godown managers add lots but never move their status -- the admin decides
/// acceptance, settlement and rejection elsewhere.
///
/// A lot an accepted return booked cannot be deleted -- the server refuses the
/// delete with a 400, so the UI never offers it.
class InwardRawDetailScreen extends StatelessWidget {
  final InwardRawMaterial lot;

  const InwardRawDetailScreen({super.key, required this.lot});

  static Future<void> push(
    BuildContext context, {
    required InwardRawMaterial lot,
    required InwardRawCubit cubit,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<InwardRawCubit>.value(
          value: cubit,
          child: InwardRawDetailScreen(lot: lot),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InwardRawCubit, InwardRawState>(
      builder: (context, state) {
        final InwardRawMaterial current = state.lots.firstWhere(
          (item) => item.publicId == lot.publicId,
          orElse: () => lot,
        );

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
              AppStrings.INWARD_DETAIL_TITLE,
              style: AppTypography.titleMedium,
            ),
            actions: [
              if (current.canDelete)
                IconButton(
                  tooltip: AppStrings.DELETE,
                  onPressed: state.isMutating
                      ? null
                      : () => _confirmDelete(context, current),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: AppSizes.ICON_LG,
                    color: AppColors.ERROR,
                  ),
                ),
              const SizedBox(width: AppSpacing.XS4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.SMD12,
              AppSpacing.SMD12,
              AppSpacing.SMD12,
              AppSizes.ORDER_LIST_BOTTOM_INSET,
            ),
            children: [
              _HeaderCard(lot: current),
              if (current.isReturnLot) ...[
                const SizedBox(height: AppSpacing.SMD12),
                const _ReturnLotNotice(),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InwardRawMaterial current,
  ) async {
    final InwardRawCubit cubit = context.read<InwardRawCubit>();

    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.INWARD_DELETE_TITLE,
      body: AppStrings.INWARD_DELETE_BODY,
      confirmLabel: AppStrings.DELETE,
      confirmColor: AppColors.ERROR,
    );
    if (!confirmed || !context.mounted) return;

    final bool succeeded = await cubit.deleteLot(current.publicId);
    if (!context.mounted) return;

    if (succeeded) {
      ToastUtils.showSuccess(context, AppStrings.INWARD_LOT_DELETED);
      Navigator.of(context).pop();
      return;
    }
    ToastUtils.showServerError(
      context,
      cubit.state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
    );
  }
}

/// Who, what and how much, headed by a tinted band carrying the product name
/// and current status -- the same weight `OrderDetailScreen` gives its header.
class _HeaderCard extends StatelessWidget {
  final InwardRawMaterial lot;

  const _HeaderCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            color: AppColors.PRIMARY_SURFACE,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    lot.product.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.TEXT_PRIMARY,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.SM8),
                InwardRawStatusBadge(status: lot.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_LOT_NO,
                  value: lot.lotNo,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_FARMER_NAME,
                  value: lot.farmerName,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_PARTY,
                  value: lot.party.name,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_QUANTITY_KG,
                  value: '${lot.quantityKg} ${AppStrings.KG_LABEL}',
                  valueColor: AppColors.PRIMARY,
                  isValueStrong: true,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_LAB_SAMPLING_DATE,
                  value: DateFormatter.day(lot.labSamplingDate),
                ),
                if (InwardRawStatusX.isDated(lot.status)) ...[
                  const _RowSeparator(),
                  _DetailRow(
                    label: AppStrings.INWARD_FIELD_EFFECTIVE_DATE,
                    value: DateFormatter.day(lot.effectiveDate),
                  ),
                ],
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_CREATED_BY,
                  value: lot.createdBy?.name ?? '',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnLotNotice extends StatelessWidget {
  const _ReturnLotNotice();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.MD16),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: AppSizes.ICON_MD,
              color: AppColors.TEXT_SECONDARY,
            ),
            const SizedBox(width: AppSpacing.SM8),
            Expanded(
              child: Text(
                AppStrings.INWARD_RETURN_LOT_NOTICE,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.TEXT_SECONDARY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isValueStrong;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isValueStrong = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final String shown = value.trim().isEmpty
        ? AppStrings.ORDER_NO_DATE
        : value;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.SMD12,
        bottom: isLast ? AppSpacing.MD16 : AppSpacing.SMD12,
      ),
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
            flex: 2,
            child: Text(
              shown,
              textAlign: TextAlign.right,
              style:
                  (isValueStrong
                          ? AppTypography.labelStrong
                          : AppTypography.bodyMedium)
                      .copyWith(color: valueColor ?? AppColors.TEXT_PRIMARY),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowSeparator extends StatelessWidget {
  const _RowSeparator();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSizes.DIVIDER_THIN,
      thickness: AppSizes.DIVIDER_THIN,
      color: AppColors.DIVIDER,
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
