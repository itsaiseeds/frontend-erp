import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/order.dart';
import 'order_status_badge.dart';

/// One order at a glance: who it is for and what state it is in, the products
/// on it, then the money. The id and booking date sit in a tinted footer so
/// the card reads top-down without competing for the headline.
class OrderCard extends StatelessWidget {
  static const int _maxProductChips = 2;

  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

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
                    _Header(order: order),
                    const SizedBox(height: AppSpacing.SMD12),
                    _Products(order: order, maxChips: _maxProductChips),
                  ],
                ),
              ),
              _Footer(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Order order;

  const _Header({required this.order});

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
            Icons.receipt_long_rounded,
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
                order.client.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelStrong.copyWith(
                  color: AppColors.TEXT_PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.XXS2),
              _Location(order: order),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            OrderStatusBadge(status: order.status, isCompact: true),
            if (order.isVerified) ...[
              const SizedBox(height: AppSpacing.XS6),
              const _VerifiedMark(),
            ],
          ],
        ),
      ],
    );
  }
}

/// Sales-admin approval is a separate axis from the lifecycle status, so it
/// gets its own quiet marker rather than another coloured pill.
class _VerifiedMark extends StatelessWidget {
  const _VerifiedMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.verified_rounded,
          size: AppSizes.ICON_SM,
          color: AppColors.SUCCESS,
        ),
        const SizedBox(width: AppSpacing.XXS2),
        Text(
          AppStrings.ORDER_VERIFIED,
          style: AppTypography.labelSmall.copyWith(color: AppColors.SUCCESS),
        ),
      ],
    );
  }
}

class _Location extends StatelessWidget {
  final Order order;

  const _Location({required this.order});

  @override
  Widget build(BuildContext context) {
    final String city = order.cityName.trim();
    final String text = city.isEmpty ? order.deliveryAddress : city;
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: AppSizes.ICON_SM,
          color: AppColors.TEXT_SECONDARY,
        ),
        const SizedBox(width: AppSpacing.XXS2),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
      ],
    );
  }
}

/// The first few products by name, then a count of what is left -- enough to
/// recognise the order without turning the card into a list.
class _Products extends StatelessWidget {
  final Order order;
  final int maxChips;

  const _Products({required this.order, required this.maxChips});

  @override
  Widget build(BuildContext context) {
    if (order.packagings.isEmpty) return const SizedBox.shrink();

    final List<OrderPackaging> shown = order.packagings.take(maxChips).toList();
    final int remaining = order.packagings.length - shown.length;

    return Wrap(
      spacing: AppSpacing.XS6,
      runSpacing: AppSpacing.XS6,
      children: [
        for (final OrderPackaging line in shown)
          _ProductChip(label: line.productName, quantity: line.quantity),
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
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.PRIMARY,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final Order order;

  const _Footer({required this.order});

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
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: AppSizes.ICON_SM,
                  color: AppColors.TEXT_DISABLED,
                ),
                const SizedBox(width: AppSpacing.XS6),
                Flexible(
                  child: Text(
                    DateFormatter.dayTime(order.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
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
                CurrencyFormatter.rupees(order.totalAmount),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
              const SizedBox(height: AppSpacing.XXS2),
              Text(
                '${order.bagCount} ${AppStrings.ORDER_BAGS_SUFFIX} - '
                '${order.totalPackets} ${AppStrings.ORDER_PACKETS_SUFFIX}',
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
