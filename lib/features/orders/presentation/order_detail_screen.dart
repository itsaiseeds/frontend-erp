import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/image_url_resolver.dart';
import '../data/models/order.dart';
import 'widgets/order_status_badge.dart';

/// The list payload carries everything a preview needs, so the detail renders
/// from the card that was tapped rather than a second request.
class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

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
          AppStrings.ORDER_DETAIL_TITLE,
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
          _HeaderCard(order: order),
          const SizedBox(height: AppSpacing.SMD12),
          _ItemsCard(order: order),
          const SizedBox(height: AppSpacing.SMD12),
          _DeliveryCard(order: order),
          const SizedBox(height: AppSpacing.SMD12),
          _VerificationCard(order: order),
        ],
      ),
    );
  }
}

/// Who and what state, then the two numbers that matter, on a tinted panel.
class _HeaderCard extends StatelessWidget {
  final Order order;

  const _HeaderCard({required this.order});

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
                        order.client.companyName,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.TEXT_PRIMARY,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.SM8),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.XS6),
                Text(
                  order.publicId,
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
                    label: AppStrings.ORDER_TOTAL_AMOUNT,
                    value: CurrencyFormatter.rupees(order.totalAmount),
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
                    label: AppStrings.ORDER_TOTAL_PACKETS,
                    value: '${order.totalPackets}',
                  ),
                ),
                Container(
                  width: AppSizes.BORDER_THIN,
                  height: AppSizes.CLIENT_STAT_DIVIDER,
                  color: AppColors.BORDER,
                ),
                Expanded(
                  child: _Metric(
                    label: AppStrings.ORDER_ITEMS,
                    value: '${order.itemCount}',
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
  final Order order;

  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.packagings.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.ORDER_ITEMS,
            trailing: '${order.packagings.length}',
          ),
          for (int index = 0; index < order.packagings.length; index++) ...[
            if (index > 0) const _RowSeparator(),
            _PackagingRow(line: order.packagings[index]),
          ],
        ],
      ),
    );
  }
}

/// One ordered bag in full: what it looks like, how it is packed, what it was
/// charged at and what the line came to.
class _PackagingRow extends StatelessWidget {
  final OrderPackaging line;

  const _PackagingRow({required this.line});

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
              _LineThumbnail(url: line.imageUrl),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      line.productName,
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
                        _PackChip(label: line.totalWeightSummary),
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
                  '${AppStrings.ORDER_QUANTITY_PREFIX} ${line.quantity}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.PRIMARY,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.SM8),
          _PriceRow(line: line),
        ],
      ),
    );
  }
}

/// Shows the agreed price, and the list price struck through beside it when
/// the order was booked at something else.
class _PriceRow extends StatelessWidget {
  final OrderPackaging line;

  const _PriceRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                CurrencyFormatter.rupees(line.negotiatedSellingPrice),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.TEXT_PRIMARY,
                ),
              ),
              const SizedBox(width: AppSpacing.XXS2),
              Text(
                AppStrings.ORDER_BAG_PRICE,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.TEXT_DISABLED,
                ),
              ),
              if (line.isNegotiated) ...[
                const SizedBox(width: AppSpacing.XS6),
                Text(
                  CurrencyFormatter.rupees(line.sellingPrice),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_DISABLED,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Text(
          CurrencyFormatter.rupees(line.lineTotal),
          style: AppTypography.labelMedium.copyWith(color: AppColors.PRIMARY),
        ),
      ],
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

class _LineThumbnail extends StatelessWidget {
  final String url;

  const _LineThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final String resolved = ImageUrlResolver.resolve(url);

    return Container(
      width: AppSizes.ORDER_LINE_THUMB,
      height: AppSizes.ORDER_LINE_THUMB,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        borderRadius: BorderRadius.circular(AppRadius.MD),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolved.isEmpty
          ? const Icon(
              Icons.inventory_2_outlined,
              size: AppSizes.ICON_MD,
              color: AppColors.TEXT_DISABLED,
            )
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.inventory_2_outlined,
                size: AppSizes.ICON_MD,
                color: AppColors.TEXT_DISABLED,
              ),
            ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Order order;

  const _DeliveryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionTitle(
            icon: Icons.local_shipping_outlined,
            title: AppStrings.ORDER_DELIVERY,
          ),
          _DetailRow(
            label: AppStrings.ORDER_DELIVERY_ADDRESS,
            value: order.deliveryAddress,
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.ORDER_EXPECTED_DELIVERY,
            value: DateFormatter.calendarDay(order.expectedDeliveryDate),
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.ORDER_DISPATCH_MODE,
            value: order.isAgencyDispatch
                ? AppStrings.ORDER_DISPATCH_AGENCY
                : AppStrings.ORDER_DISPATCH_PRIVATE,
          ),
          const _RowSeparator(),
          _DetailRow(
            label: AppStrings.ORDER_BOOKED_ON,
            value: DateFormatter.dayTimeFull(order.createdAt),
          ),
        ],
      ),
    );
  }
}

/// Sales-admin approval. Shown either way -- "awaiting" is information a
/// sales person acts on, not an empty state to hide.
class _VerificationCard extends StatelessWidget {
  final Order order;

  const _VerificationCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final bool isVerified = order.isVerified;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionTitle(
            icon: isVerified
                ? Icons.verified_rounded
                : Icons.hourglass_empty_rounded,
            title: AppStrings.ORDER_VERIFICATION,
          ),
          if (!isVerified)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.MD16,
                0,
                AppSpacing.MD16,
                AppSpacing.MD16,
              ),
              child: Text(AppStrings.ORDER_AWAITING_VERIFICATION),
            )
          else ...[
            _DetailRow(
              label: AppStrings.ORDER_VERIFIED_BY,
              value: order.verifiedBy,
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.ORDER_VERIFIED_ON,
              value: DateFormatter.dayTimeFull(order.verifiedAt),
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
    final String? count = trailing;

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
          if (count != null)
            Text(
              count,
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
