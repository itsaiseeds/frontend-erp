import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../orders/data/models/order_status.dart';
import '../data/models/return_order.dart';
import 'widgets/return_order_status_badge.dart';

/// A return, on its own.
///
/// Deliberately not the order the return was raised against: someone opening a
/// return wants to see what came back and where it stands, not the order it
/// came from. For the same reason the app bar carries no actions -- raising a
/// return and opening a challan are things done from the order, never from the
/// return itself.
class ReturnOrderDetailScreen extends StatelessWidget {
  final ReturnOrder returnOrder;

  const ReturnOrderDetailScreen({super.key, required this.returnOrder});

  static Future<void> open(BuildContext context, ReturnOrder returnOrder) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReturnOrderDetailScreen(returnOrder: returnOrder),
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
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: AppSizes.ICON_XL,
            color: AppColors.TEXT_PRIMARY,
          ),
        ),
        title: Text(
          AppStrings.RETURN_ORDER_DETAIL_TITLE,
          style: AppTypography.titleMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.SMD12,
          AppSpacing.SMD12,
          AppSpacing.SMD12,
          AppSizes.ORDER_LIST_BOTTOM_INSET,
        ),
        children: [
          _HeaderCard(returnOrder: returnOrder),
          const SizedBox(height: AppSpacing.SMD12),
          _ItemsCard(returnOrder: returnOrder),
          const SizedBox(height: AppSpacing.SMD12),
          _DetailsCard(returnOrder: returnOrder),
          const SizedBox(height: AppSpacing.SMD12),
          _ApprovalCard(returnOrder: returnOrder),
        ],
      ),
    );
  }
}

/// Who and what state, then the three numbers that matter, on a tinted panel.
class _HeaderCard extends StatelessWidget {
  final ReturnOrder returnOrder;

  const _HeaderCard({required this.returnOrder});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        returnOrder.client.companyName,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.TEXT_PRIMARY,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.SM8),
                    ReturnOrderStatusBadge(status: returnOrder.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.XS6),
                Text(
                  returnOrder.publicId,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: AppStrings.RETURN_ORDER_TOTAL_AMOUNT,
                    value: CurrencyFormatter.rupees(returnOrder.totalAmount),
                    isEmphasised: true,
                  ),
                ),
                Container(
                  width: AppSizes.BORDER_THIN,
                  height: AppSizes.CLIENT_STAT_DIVIDER,
                  color: AppColors.BORDER,
                ),
                Expanded(
                  child: _Metric(
                    label: AppStrings.RETURN_ORDER_TOTAL_PACKETS,
                    value: '${returnOrder.totalPackets}',
                  ),
                ),
                Container(
                  width: AppSizes.BORDER_THIN,
                  height: AppSizes.CLIENT_STAT_DIVIDER,
                  color: AppColors.BORDER,
                ),
                Expanded(
                  child: _Metric(
                    label: AppStrings.RETURN_ORDER_TOTAL_KG,
                    value:
                        '${ReturnOrderItem.trimWeight(returnOrder.totalKg)} kg',
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasised;

  const _Metric({
    required this.label,
    required this.value,
    this.isEmphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: isEmphasised ? AppColors.PRIMARY : AppColors.TEXT_PRIMARY,
          ),
        ),
        const SizedBox(height: AppSpacing.XXS2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
      ],
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final ReturnOrder returnOrder;

  const _ItemsCard({required this.returnOrder});

  @override
  Widget build(BuildContext context) {
    if (returnOrder.items.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.RETURN_ORDER_ITEMS,
            trailing: '${returnOrder.items.length}',
          ),
          for (int index = 0; index < returnOrder.items.length; index++) ...[
            if (index > 0) const _RowSeparator(),
            _ReturnItemRow(line: returnOrder.items[index]),
          ],
        ],
      ),
    );
  }
}

/// One returned line: what it is, how much of it came back, and what it came
/// to.
class _ReturnItemRow extends StatelessWidget {
  final ReturnOrderItem line;

  const _ReturnItemRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.MD16,
        vertical: AppSpacing.SMD12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.ORDER_LINE_THUMB,
                height: AppSizes.ORDER_LINE_THUMB,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.SURFACE_VARIANT,
                  borderRadius: BorderRadius.circular(AppRadius.MD),
                ),
                clipBehavior: Clip.antiAlias,
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: AppSizes.ICON_MD,
                  color: AppColors.TEXT_DISABLED,
                ),
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.XS6),
                    Wrap(
                      spacing: AppSpacing.XS6,
                      runSpacing: AppSpacing.XS6,
                      children: [
                        _PackChip(label: line.packetSummary),
                        _PackChip(
                          label:
                              '${ReturnOrderItem.trimWeight(line.kg)} kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.SM8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.SM8,
                  vertical: AppSpacing.XXS2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.PRIMARY_SURFACE,
                  borderRadius: BorderRadius.circular(AppRadius.SM),
                ),
                child: Text(
                  '${AppStrings.ORDER_QUANTITY_PREFIX} ${line.packets}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.PRIMARY,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.SM8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      CurrencyFormatter.rupees(line.pricePerPacket),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.TEXT_PRIMARY,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.XXS2),
                    Text(
                      AppStrings.RETURN_ORDER_PER_PACKET,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.TEXT_DISABLED,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.SM8),
              Text(
                CurrencyFormatter.rupees(line.lineTotal),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackChip extends StatelessWidget {
  final String label;

  const _PackChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.PRIMARY),
        borderRadius: BorderRadius.circular(AppRadius.SM),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.TEXT_PRIMARY),
      ),
    );
  }
}

/// The paperwork behind the return: which order, when, and who raised it.
class _DetailsCard extends StatelessWidget {
  final ReturnOrder returnOrder;

  const _DetailsCard({required this.returnOrder});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_long_outlined,
            title: AppStrings.RETURN_ORDER_SUMMARY,
          ),
          _DetailRow(
            label: AppStrings.RETURN_ORDER_FIELD_DATE,
            value: DateFormatter.calendarDay(returnOrder.returnDate),
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.RETURN_ORDER_ORDER_REF,
            value: returnOrder.order.publicId,
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.RETURN_ORDER_ORDER_STATUS,
            value: OrderStatusX.labelOf(
              OrderStatusX.fromRaw(returnOrder.order.status),
            ),
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.RETURN_ORDER_RAISED_BY,
            value: returnOrder.createdBy?.name ?? '',
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.RETURN_ORDER_RAISED_ON,
            value: DateFormatter.dayTimeFull(returnOrder.createdAt),
          ),
        ],
      ),
    );
  }
}

/// Where the return sits in the admin's hands: still waiting, taken back into
/// stock, or refused.
class _ApprovalCard extends StatelessWidget {
  final ReturnOrder returnOrder;

  const _ApprovalCard({required this.returnOrder});

  bool get _hasInwardLots =>
      returnOrder.inwardRawMaterials.isNotEmpty ||
      returnOrder.inwardOtherMaterials.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final ReturnOrderStatus status = returnOrder.status;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(
            icon: status == ReturnOrderStatus.accepted
                ? Icons.verified_rounded
                : status == ReturnOrderStatus.rejected
                ? Icons.cancel_outlined
                : Icons.hourglass_empty_rounded,
            title: AppStrings.RETURN_ORDER_APPROVAL,
          ),
          if (status == ReturnOrderStatus.pending)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.MD16,
                0,
                AppSpacing.MD16,
                AppSpacing.MD16,
              ),
              child: Text(AppStrings.RETURN_ORDER_AWAITING_APPROVAL),
            )
          else if (status == ReturnOrderStatus.accepted) ...[
            _DetailRow(
              label: AppStrings.RETURN_ORDER_ACCEPTED_BY,
              value: returnOrder.verifiedBy?.name ?? '',
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.RETURN_ORDER_ACCEPTED_ON,
              value: DateFormatter.dayTimeFull(returnOrder.verifiedAt),
            ),
            if (returnOrder.includeInOtherRawMaterials != null) ...[
              const _RowSeparator(),
              _DetailRow(
                label: AppStrings.RETURN_ORDER_MATERIALS,
                value: returnOrder.includeInOtherRawMaterials!
                    ? AppStrings.RETURN_ORDER_MATERIALS_BOOKED
                    : AppStrings.RETURN_ORDER_MATERIALS_NOT_BOOKED,
              ),
            ],
            if (_hasInwardLots) ...[
              const _RowSeparator(),
              if (returnOrder.inwardRawMaterials.isNotEmpty) ...[
                _DetailRow(
                  label: AppStrings.RETURN_ORDER_INWARD_RAW_TITLE,
                  value: returnOrder.inwardRawMaterials.join(', '),
                ),
                const _RowSeparator(),
              ],
              if (returnOrder.inwardOtherMaterials.isNotEmpty)
                _DetailRow(
                  label: AppStrings.RETURN_ORDER_INWARD_OTHER_TITLE,
                  value: returnOrder.inwardOtherMaterials.join(', '),
                ),
            ],
          ] else ...[
            _DetailRow(
              label: AppStrings.RETURN_ORDER_REJECTED_BY,
              value: returnOrder.rejectedBy?.name ?? '',
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.RETURN_ORDER_REJECTED_ON,
              value: DateFormatter.dayTimeFull(returnOrder.rejectedAt),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final String shown = value.trim().isEmpty
        ? AppStrings.ORDER_NO_DATE
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.MD16,
        vertical: AppSpacing.SMD12,
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        AppSpacing.MD16,
        AppSpacing.MD16,
        AppSpacing.SM8,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.ICON_MD, color: AppColors.PRIMARY),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(child: Text(title, style: AppTypography.labelStrong)),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
      child: Divider(
        height: AppSizes.DIVIDER_THIN,
        thickness: AppSizes.DIVIDER_THIN,
        color: AppColors.DIVIDER,
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
