import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/return_order.dart';
import '../../data/models/return_order_draft_item.dart';
import '../../data/models/return_order_prefill.dart';

/// One product-and-weight line on the return.
///
/// The product is fixed once a card exists -- the backend keys a return line on
/// product plus weight, so a card is one pair. Which weight of the product it
/// is can still change, and the choices are chips rather than another dropdown
/// because a packet weight is a small closed set the salesperson can read at a
/// glance.
class ReturnItemCard extends StatefulWidget {
  final ReturnOrderDraftItem item;
  final List<ReturnOrderPrefillLine> weights;
  final bool Function(num weight) isWeightTaken;
  final ValueChanged<num> onWeightChanged;
  final ValueChanged<int> onPacketsChanged;
  final ValueChanged<num> onPriceChanged;
  final VoidCallback onRemove;
  final VoidCallback onAddAnotherWeight;

  const ReturnItemCard({
    super.key,
    required this.item,
    required this.weights,
    required this.isWeightTaken,
    required this.onWeightChanged,
    required this.onPacketsChanged,
    required this.onPriceChanged,
    required this.onRemove,
    required this.onAddAnotherWeight,
  });

  @override
  State<ReturnItemCard> createState() => _ReturnItemCardState();
}

class _ReturnItemCardState extends State<ReturnItemCard> {
  late final TextEditingController _packetsController;
  late final TextEditingController _priceController;

  String? _packetsError;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _packetsController = TextEditingController(text: '${widget.item.packets}');
    _priceController = TextEditingController(
      text: widget.item.pricePerPacket.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(covariant ReturnItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Switching weight rewrites the count and the price underneath, so the
    // fields have to follow or they would submit the old values.
    if (oldWidget.item.packetWeight != widget.item.packetWeight) {
      _packetsController.text = '${widget.item.packets}';
      _priceController.text = widget.item.pricePerPacket.toStringAsFixed(2);
      setState(() {
        _packetsError = null;
        _priceError = null;
      });
      return;
    }

    if (oldWidget.item.packets != widget.item.packets &&
        _packetsController.text != '${widget.item.packets}') {
      _packetsController.text = '${widget.item.packets}';
    }

    if (oldWidget.item.pricePerPacket != widget.item.pricePerPacket &&
        _priceController.text !=
            widget.item.pricePerPacket.toStringAsFixed(2)) {
      _priceController.text = widget.item.pricePerPacket.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _packetsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _stepPackets(int delta) {
    final int next = widget.item.packets + delta;
    if (next < 1 || next > widget.item.maxPackets) return;
    setState(() => _packetsError = null);
    widget.onPacketsChanged(next);
  }

  void _commitPackets(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) {
      setState(() => _packetsError = AppStrings.VALIDATION_RETURN_PACKETS_REQUIRED);
      _packetsController.text = '${widget.item.packets}';
      return;
    }

    final int? value = int.tryParse(text);
    if (value == null || value < 1 || value > widget.item.maxPackets) {
      setState(() {
        _packetsError = AppStrings.VALIDATION_RETURN_PACKETS.replaceAll(
          '%s',
          '${widget.item.maxPackets}',
        );
      });
      _packetsController.text = '${widget.item.packets}';
      return;
    }

    setState(() => _packetsError = null);
    widget.onPacketsChanged(value);
  }

  void _commitPrice(String raw) {
    final String text = raw.trim();
    final num? value = num.tryParse(text);

    if (text.isEmpty || value == null || value < 0) {
      setState(() => _priceError = AppStrings.VALIDATION_RETURN_PRICE);
      _priceController.text = widget.item.pricePerPacket.toStringAsFixed(2);
      return;
    }

    setState(() => _priceError = null);
    widget.onPriceChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final ReturnOrderDraftItem item = widget.item;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(item: item, onRemove: widget.onRemove),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.MD16,
              0,
              AppSpacing.MD16,
              AppSpacing.MD16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _WeightChips(
                  weights: widget.weights,
                  selectedWeight: item.packetWeight,
                  isTaken: widget.isWeightTaken,
                  onSelected: widget.onWeightChanged,
                ),
                const SizedBox(height: AppSpacing.MD16),
                _PacketsRow(
                  item: item,
                  controller: _packetsController,
                  errorText: _packetsError,
                  onStep: _stepPackets,
                  onCommitted: _commitPackets,
                ),
                const SizedBox(height: AppSpacing.MD16),
                _PriceField(
                  controller: _priceController,
                  errorText: _priceError,
                  onCommitted: _commitPrice,
                ),
                const SizedBox(height: AppSpacing.SMD12),
                const Divider(
                  height: AppSizes.DIVIDER_THIN,
                  thickness: AppSizes.DIVIDER_THIN,
                  color: AppColors.DIVIDER,
                ),
                _LineTotal(item: item),
                const SizedBox(height: AppSpacing.SMD12),
                _AddAnotherWeightButton(onTap: widget.onAddAnotherWeight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ReturnOrderDraftItem item;
  final VoidCallback onRemove;

  const _Header({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        AppSpacing.SMD12,
        AppSpacing.XS6,
        AppSpacing.SMD12,
      ),
      color: AppColors.PRIMARY_SURFACE,
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: AppSizes.ICON_MD,
            color: AppColors.PRIMARY,
          ),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(
            child: Text(
              item.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelStrong.copyWith(
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: AppStrings.CLIENT_REMOVE,
            icon: const Icon(
              Icons.close_rounded,
              size: AppSizes.ICON_MD,
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChips extends StatelessWidget {
  final List<ReturnOrderPrefillLine> weights;
  final num selectedWeight;
  final bool Function(num weight) isTaken;
  final ValueChanged<num> onSelected;

  const _WeightChips({
    required this.weights,
    required this.selectedWeight,
    required this.isTaken,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (weights.length <= 1) return const SizedBox.shrink();

    final String selectedKey = ReturnOrderItem.trimWeight(selectedWeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.RETURN_ORDER_PACKET_WEIGHT,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
        const SizedBox(height: AppSpacing.SM8),
        Wrap(
          spacing: AppSpacing.SM8,
          runSpacing: AppSpacing.SM8,
          children: [
            for (final ReturnOrderPrefillLine line in weights)
              _WeightChip(
                label: '${line.weightKey} kg',
                isSelected: line.weightKey == selectedKey,
                isEnabled: line.isReturnable && !isTaken(line.packetWeight),
                onTap: () => onSelected(line.packetWeight),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeightChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _WeightChip({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = isSelected
        ? AppColors.PRIMARY
        : AppColors.SURFACE;
    final Color border = isSelected ? AppColors.PRIMARY : AppColors.BORDER;
    final Color text = !isEnabled
        ? AppColors.TEXT_DISABLED
        : isSelected
        ? AppColors.TEXT_ON_PRIMARY
        : AppColors.TEXT_PRIMARY;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.FULL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.SMD12,
            vertical: AppSpacing.XS6,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(AppRadius.FULL),
          ),
          child: Text(label, style: AppTypography.labelSmall.copyWith(color: text)),
        ),
      ),
    );
  }
}

class _PacketsRow extends StatelessWidget {
  final ReturnOrderDraftItem item;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<int> onStep;
  final ValueChanged<String> onCommitted;

  const _PacketsRow({
    required this.item,
    required this.controller,
    required this.errorText,
    required this.onStep,
    required this.onCommitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.RETURN_ORDER_RETURN_PACKETS,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.XXS2),
                  Text(
                    AppStrings.RETURN_ORDER_MAX_PACKETS.replaceAll(
                      '%s',
                      '${item.maxPackets}',
                    ),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.TEXT_DISABLED,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.SMD12),
            _StepperButton(
              icon: Icons.remove_rounded,
              isEnabled: item.packets > 1,
              onTap: () => onStep(-1),
            ),
            SizedBox(width: 5,),
            Container(
              width: AppSizes.STEPPER_COUNT_WIDTH + AppSpacing.LG24,
              height: AppSizes.STEPPER_HEIGHT,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.SURFACE,
                border: Border.all(color: AppColors.BORDER),
                borderRadius: BorderRadius.circular(AppRadius.SM),
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTypography.labelMedium,
                cursorColor: AppColors.PRIMARY,
                onSubmitted: onCommitted,
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                  onCommitted(controller.text);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            SizedBox(width: 5,),
            _StepperButton(
              icon: Icons.add_rounded,
              isEnabled: item.packets < item.maxPackets,
              onTap: () => onStep(1),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.XS4),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.ERROR),
          ),
        ],
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEnabled ? AppColors.PRIMARY_SURFACE : AppColors.SURFACE_VARIANT,
      borderRadius: BorderRadius.circular(AppRadius.SM),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: AppSizes.STEPPER_BUTTON,
          height: AppSizes.STEPPER_HEIGHT,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? AppColors.PRIMARY : AppColors.BORDER,
            ),
            borderRadius: BorderRadius.circular(AppRadius.SM),
          ),
          child: Icon(
            icon,
            size: AppSizes.ICON_SM,
            color: isEnabled ? AppColors.PRIMARY : AppColors.TEXT_DISABLED,
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onCommitted;

  const _PriceField({
    required this.controller,
    required this.errorText,
    required this.onCommitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.RETURN_ORDER_PRICE_PER_PACKET,
          style: AppTypography.labelSmall.copyWith(color: AppColors.TEXT_SECONDARY),
        ),
        const SizedBox(height: AppSpacing.SM8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: AppTypography.bodyMedium,
          cursorColor: AppColors.PRIMARY,
          onSubmitted: onCommitted,
          onTapOutside: (_) {
            FocusScope.of(context).unfocus();
            onCommitted(controller.text);
          },
          decoration: InputDecoration(
            prefixText: '₹',
            prefixStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
            filled: true,
            fillColor: AppColors.SURFACE,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.MD16,
              vertical: AppSpacing.SMD12,
            ),
            border: _border(
              errorText == null ? AppColors.BORDER : AppColors.ERROR,
            ),
            enabledBorder: _border(
              errorText == null ? AppColors.BORDER : AppColors.ERROR,
            ),
            focusedBorder: _border(
              AppColors.BORDER_FOCUSED,
              width: AppSizes.BORDER_THICK,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.XS4),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.ERROR),
          ),
        ],
      ],
    );
  }

  static OutlineInputBorder _border(
    Color color, {
    double width = AppSizes.BORDER_THIN,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.CHIP),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _LineTotal extends StatelessWidget {
  final ReturnOrderDraftItem item;

  const _LineTotal({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          AppStrings.RETURN_ORDER_LINE_TOTAL,
          style: AppTypography.bodySmall.copyWith(color: AppColors.TEXT_SECONDARY),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Expanded(
          child: Text(
            '${item.packets} x ${item.weightLabel} = '
            '${ReturnOrderItem.trimWeight(item.kg)} kg',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.TEXT_DISABLED,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Text(
          CurrencyFormatter.rupees(item.lineTotal),
          style: AppTypography.labelMedium.copyWith(color: AppColors.PRIMARY),
        ),
      ],
    );
  }
}

class _AddAnotherWeightButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAnotherWeightButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.SURFACE_VARIANT,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.SMD12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: AppSizes.ICON_SM,
                color: AppColors.PRIMARY,
              ),
              const SizedBox(width: AppSpacing.XS6),
              Text(
                AppStrings.RETURN_ORDER_ADD_MORE_WEIGHT,
                style: AppTypography.labelSmall.copyWith(color: AppColors.PRIMARY),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
