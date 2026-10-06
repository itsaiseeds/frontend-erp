import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../data/models/inward_other_material.dart';
import 'bloc/inward_other_cubit.dart';
import 'bloc/inward_other_state.dart';

/// View-only aside from delete: the PATCH endpoint has no writable fields,
/// so a mistyped booking is corrected by deleting and re-booking, never by
/// editing.
class InwardOtherDetailScreen extends StatelessWidget {
  final InwardOtherMaterial lot;

  const InwardOtherDetailScreen({super.key, required this.lot});

  static Future<void> push(
    BuildContext context, {
    required InwardOtherMaterial lot,
    required InwardOtherCubit cubit,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<InwardOtherCubit>.value(
          value: cubit,
          child: InwardOtherDetailScreen(lot: lot),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InwardOtherCubit, InwardOtherState>(
      builder: (context, state) {
        final InwardOtherMaterial current = state.lots.firstWhere(
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
    InwardOtherMaterial current,
  ) async {
    final InwardOtherCubit cubit = context.read<InwardOtherCubit>();

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

/// Mirrors `InwardRawDetailScreen`'s header: a tinted band for the product
/// name, divided rows for everything else.
class _HeaderCard extends StatelessWidget {
  final InwardOtherMaterial lot;

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
            child: Text(
              lot.productName,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_MATERIAL_TYPE,
                  value: lot.materialTypeName,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_PARTY,
                  value: lot.party.name,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_QUANTITY,
                  value: lot.quantity,
                  valueColor: AppColors.PRIMARY,
                  isValueStrong: true,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.INWARD_FIELD_EFFECTIVE_DATE,
                  value: DateFormatter.day(lot.effectiveDate),
                ),
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
