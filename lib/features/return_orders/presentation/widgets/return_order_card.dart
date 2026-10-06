import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/return_order.dart';
import 'return_order_status_badge.dart';

/// One return at a glance: whose goods are coming back and where they have got
/// to, what is on it, then the weight and the money. The return id and the
/// return date sit in a tinted footer so the card reads top-down without
/// competing for the headline -- the same shape as the order card.
class ReturnOrderCard extends StatelessWidget {
  static const int _maxProductChips = 2;

  final ReturnOrder returnOrder;
  final VoidCallback? onTap;

  const ReturnOrderCard({super.key, required this.returnOrder, this.onTap});

  @override
  Widget build(BuildContext context) {
    // The border sits on the clipping shape itself. Drawn on an inner child it
    // would be shaved away at the corners by the antialiased clip.
    return Material(
      color: AppColors.SURFACE,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.PRIMARY_SURFACE,
        highlightColor: AppColors.PRIMARY_SURFACE,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.BORDER_THIN),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.SMD12,
                  AppSpacing.SMD12,
                  AppSpacing.SMD12,
                  AppSpacing.SM8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(returnOrder: returnOrder),
                    const SizedBox(height: AppSpacing.SMD12),
                    _Products(
                      returnOrder: returnOrder,
                      maxChips: _maxProductChips,
                    ),
                  ],
                ),
              ),
              _Footer(returnOrder: returnOrder),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ReturnOrder returnOrder;

  const _Header({required this.returnOrder});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizes.ORDER_ICON_BOX,
          height: AppSizes.ORDER_ICON_BOX,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.PRIMARY_SURFACE,
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: const Icon(
            Icons.assignment_return_outlined,
            size: AppSizes.ICON_MD,
            color: AppColors.PRIMARY,
          ),
        ),
        const SizedBox(width: AppSpacing.SMD12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                returnOrder.client.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelStrong.copyWith(
                  color: AppColors.TEXT_PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.XXS2),
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: AppSizes.ICON_SM,
                    color: AppColors.TEXT_SECONDARY,
                  ),
                  const SizedBox(width: AppSpacing.XXS2),
                  Flexible(
                    child: Text(
                      returnOrder.order.publicId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.TEXT_SECONDARY,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.SM8),
        ReturnOrderStatusBadge(status: returnOrder.status, isCompact: true),
      ],
    );
  }
}

/// The first few products by name, each with how many packets of it are coming
/// back, then a count of what is left -- enough to recognise the return without
/// turning the card into a list.
class _Products extends StatelessWidget {
  final ReturnOrder returnOrder;
  final int maxChips;

  const _Products({required this.returnOrder, required this.maxChips});

  @override
  Widget build(BuildContext context) {
    if (returnOrder.items.isEmpty) return const SizedBox.shrink();

    final List<ReturnOrderItem> shown = returnOrder.items.take(maxChips).toList();
    final int remaining = returnOrder.items.length - shown.length;

    return Wrap(
      spacing: AppSpacing.XS6,
      runSpacing: AppSpacing.XS6,
      children: [
        for (final ReturnOrderItem line in shown)
          _ProductChip(label: line.product.name, quantity: line.packets),
        if (remaining > 0)
          _ProductChip(
            label:
                '${AppStrings.ORDER_MORE_PRODUCTS_PREFIX}$remaining '
                '${AppStrings.ORDER_MORE_PRODUCTS_SUFFIX}',
          ),
      ],
    );
  }
}

class _ProductChip extends StatelessWidget {
  final String label;
  final int? quantity;

  const _ProductChip({required this.label, this.quantity});

  @override
  Widget build(BuildContext context) {
    final int? count = quantity;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: AppSpacing.XS6),
            Container(
              width: AppSizes.ORDER_DOT,
              height: AppSizes.ORDER_DOT,
              decoration: const BoxDecoration(
                color: AppColors.PRIMARY,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.XS6),
            Text(
              '${AppStrings.ORDER_QUANTITY_PREFIX} $count',
              style: AppTypography.labelSmall.copyWith(color: AppColors.PRIMARY),
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ReturnOrder returnOrder;

  const _Footer({required this.returnOrder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SMD12,
        vertical: AppSpacing.SM8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.BACKGROUND,
        border: Border(top: BorderSide(color: AppColors.BORDER)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  returnOrder.publicId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
                const SizedBox(height: AppSpacing.XXS2),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: AppSizes.ICON_SM,
                      color: AppColors.TEXT_DISABLED,
                    ),
                    const SizedBox(width: AppSpacing.XS6),
                    Flexible(
                      child: Text(
                        DateFormatter.calendarDay(returnOrder.returnDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.TEXT_DISABLED,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.SM8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.rupees(returnOrder.totalAmount),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.XXS2),
              Text(
                '${returnOrder.totalPackets} ${AppStrings.ORDER_PACKETS_SUFFIX} - '
                '${ReturnOrderItem.trimWeight(returnOrder.totalKg)} kg',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.TEXT_DISABLED,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
