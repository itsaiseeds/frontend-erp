import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/models/return_order.dart';
import '../data/models/return_order_draft_item.dart';
import '../data/models/return_order_prefill.dart';
import '../data/return_orders_repository.dart';
import 'bloc/return_order_form_cubit.dart';
import 'bloc/return_order_form_state.dart';
import 'widgets/return_item_card.dart';

/// Raises a return against one dispatched order.
///
/// Opens on the challan: the products the order went out in, how many packets of
/// each are still returnable, and the price the API suggests per packet. Each
/// pick becomes a card where the packet size, the count and the price can be
/// set, and the AppBar's Return submits the lot.
class CreateReturnOrderScreen extends StatelessWidget {
  static const String routeName = '/return-order/create';

  final String orderPublicId;

  const CreateReturnOrderScreen({super.key, required this.orderPublicId});

  /// Opens the screen and answers whether a return was raised, so the caller
  /// can refresh whatever it is showing.
  static Future<bool?> open(BuildContext context, String orderPublicId) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateReturnOrderScreen(orderPublicId: orderPublicId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReturnOrderFormCubit>(
      create: (context) => ReturnOrderFormCubit(
        repository: ReturnOrdersRepository(
          apiClient: context.read<ApiClient>(),
        ),
        orderPublicId: orderPublicId,
      )..load(),
      child: const _CreateReturnOrderView(),
    );
  }
}

class _CreateReturnOrderView extends StatelessWidget {
  const _CreateReturnOrderView();

  Future<void> _submit(BuildContext context, ReturnOrderFormCubit cubit) async {
    final bool created = await cubit.submit();

    if (!context.mounted) return;

    if (!created) {
      final String? message = cubit.state.errorMessage;
      if (message != null) ToastUtils.showServerError(context, message);
      return;
    }

    final String publicId = cubit.state.created?.publicId ?? '';
    ToastUtils.showSuccess(
      context,
      AppStrings.RETURN_ORDER_CREATED_TITLE,
      description: AppStrings.RETURN_ORDER_CREATED_BODY.replaceAll(
        '%s',
        publicId,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReturnOrderFormCubit, ReturnOrderFormState>(
      builder: (context, state) {
        final ReturnOrderFormCubit cubit = context.read<ReturnOrderFormCubit>();

        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          appBar: AppBar(
            backgroundColor: AppColors.SURFACE,
            surfaceTintColor: AppColors.TRANSPARENT,
            elevation: 0,
            leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
            leading: IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: AppSizes.ICON_XL,
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
            title: Text(
              AppStrings.RETURN_ORDER_CREATE_TITLE,
              style: AppTypography.titleMedium,
            ),
            actions: [
              _SubmitAction(
                isEnabled: state.canSubmit,
                isBusy: state.isSubmitting,
                onPressed: () => _submit(context, cubit),
              ),
            ],
          ),
          body: DismissKeyboard(
            child: _Body(cubit: cubit, state: state),
          ),
        );
      },
    );
  }
}

/// "Return" in the AppBar rather than a footer button: it is the one action the
/// screen exists to perform, and it stays reachable while the keyboard is up.
class _SubmitAction extends StatelessWidget {
  final bool isEnabled;
  final bool isBusy;
  final VoidCallback onPressed;

  const _SubmitAction({
    required this.isEnabled,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = isEnabled && !isBusy;

    return TextButton(
      onPressed: active ? onPressed : null,
      child: isBusy
          ? const SizedBox(
              width: AppSizes.ICON_MD,
              height: AppSizes.ICON_MD,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.BORDER_MEDIUM,
                color: AppColors.PRIMARY,
              ),
            )
          : Text(
              AppStrings.RETURN_ORDER_SUBMIT,
              style: AppTypography.button.copyWith(
                color: active ? AppColors.PRIMARY : AppColors.TEXT_DISABLED,
              ),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  final ReturnOrderFormCubit cubit;
  final ReturnOrderFormState state;

  const _Body({required this.cubit, required this.state});

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.returnDate,
      firstDate: ReturnOrderFormCubit.earliestDate(),
      lastDate: ReturnOrderFormCubit.today(),
      builder: (context, child) {
        final ThemeData theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.PRIMARY,
              onPrimary: AppColors.TEXT_ON_PRIMARY,
              surface: AppColors.SURFACE,
              onSurface: AppColors.TEXT_PRIMARY,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    cubit.setReturnDate(picked);
  }

  void _addProduct(BuildContext context, ReturnOrderProduct product) {
    final String? failure = cubit.addProduct(product);
    if (failure == null) return;
    ToastUtils.showInfo(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading || state.status == ReturnOrderFormStatus.initial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.PRIMARY),
      );
    }

    if (state.hasError) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: AppStrings.RETURN_ORDERS_ERROR_TITLE,
        body: state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
      );
    }

    final String? blocked = state.blockedReason;
    if (blocked != null) {
      return _BlockedMessage(
        reason: blocked,
        liveReturnPublicId: state.prefill?.returnOrder?.publicId,
      );
    }

    final ReturnOrderPrefill prefill = state.prefill!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SMD12,
        AppSpacing.SMD12,
        AppSizes.ORDER_LIST_BOTTOM_INSET,
      ),
      children: [
        _OrderStrip(order: prefill.order),
        const SizedBox(height: AppSpacing.MD16),
        _ReturnDateField(
          value: state.returnDate,
          onTap: () => _pickDate(context),
        ),
        const SizedBox(height: AppSpacing.MD16),
        _ProductPicker(
          products: cubit.availableProducts,
          onPicked: (product) => _addProduct(context, product),
        ),
        const SizedBox(height: AppSpacing.MD16),
        if (state.items.isEmpty)
          const _Message(
            icon: Icons.add_shopping_cart_outlined,
            title: AppStrings.RETURN_ORDER_DRAFT_EMPTY_TITLE,
            body: AppStrings.RETURN_ORDER_DRAFT_EMPTY_BODY,
          )
        else ...[
          for (int index = 0; index < state.items.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.SMD12),
            _ItemTile(
              cubit: cubit,
              prefill: prefill,
              index: index,
              item: state.items[index],
              items: state.items,
            ),
          ],
          const SizedBox(height: AppSpacing.MD16),
          _Summary(state: state),
        ],
      ],
    );
  }
}

/// Who the goods are coming back from and which order, on a tinted strip -- the
/// screen is reached from an order, but a form this long needs to say so again.
class _OrderStrip extends StatelessWidget {
  final ReturnOrderPrefillOrder order;

  const _OrderStrip({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: AppSizes.ICON_LG,
            color: AppColors.PRIMARY,
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
                Text(
                  '${AppStrings.RETURN_ORDER_ORDER_REF} ${order.publicId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _ReturnDateField extends StatelessWidget {
  final DateTime value;
  final VoidCallback onTap;

  const _ReturnDateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.RETURN_ORDER_FIELD_DATE,
          style: AppTypography.labelStrong,
        ),
        const SizedBox(height: AppSpacing.SM8),
        Material(
          color: AppColors.SURFACE,
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: AppSizes.INPUT_HEIGHT,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.BORDER),
                borderRadius: BorderRadius.circular(AppRadius.CHIP),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: AppSizes.ICON_MD,
                    color: AppColors.TEXT_SECONDARY,
                  ),
                  const SizedBox(width: AppSpacing.SM8),
                  Expanded(
                    child: Text(
                      DateFormatter.calendarDay(value),
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: AppSizes.ICON_MD,
                    color: AppColors.TEXT_DISABLED,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Products only. Packaging is not something the salesperson has to know to
/// find the right product -- it is a choice per card once the product is on the
/// return. The field clears itself after each pick, so the same box serves the
/// whole list.
class _ProductPicker extends StatelessWidget {
  final List<ReturnOrderProduct> products;
  final ValueChanged<ReturnOrderProduct> onPicked;

  const _ProductPicker({required this.products, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GeoPickerField<ReturnOrderProduct>(
      label: AppStrings.RETURN_ORDER_FIELD_PRODUCT,
      hint: AppStrings.RETURN_ORDER_FIELD_PRODUCT_HINT,
      value: null,
      items: products,
      itemLabel: (product) => product.name,
      isSame: (a, b) => a.publicId == b.publicId,
      disabledHint: AppStrings.RETURN_ORDER_ALL_PRODUCTS_ADDED,
      onSelected: onPicked,
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ReturnOrderFormCubit cubit;
  final ReturnOrderPrefill prefill;
  final int index;
  final ReturnOrderDraftItem item;
  final List<ReturnOrderDraftItem> items;

  const _ItemTile({
    required this.cubit,
    required this.prefill,
    required this.index,
    required this.item,
    required this.items,
  });

  ReturnOrderProduct? _productFor(String productPublicId) {
    for (final ReturnOrderProduct product in prefill.products) {
      if (product.publicId == productPublicId) return product;
    }
    return null;
  }

  /// A weight another card already holds is not offered as a choice here: the
  /// API keys a line on product plus weight and would reject the duplicate.
  bool _isWeightTaken(num weight) {
    final String key = ReturnOrderItem.trimWeight(weight);
    for (int i = 0; i < items.length; i++) {
      if (i == index) continue;
      if (items[i].productPublicId == item.productPublicId &&
          items[i].weightKey == key) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ReturnOrderProduct? product = _productFor(item.productPublicId);
    if (product == null) return const SizedBox.shrink();

    return ReturnItemCard(
      item: item,
      weights: product.sortedLines,
      isWeightTaken: _isWeightTaken,
      onWeightChanged: (weight) {
        final String? failure = cubit.setWeight(index, weight);
        if (failure != null) ToastUtils.showInfo(context, failure);
      },
      onPacketsChanged: (packets) => cubit.setPackets(index, packets),
      onPriceChanged: (price) => cubit.setPrice(index, price),
      onRemove: () => cubit.removeItem(index),
      onAddAnotherWeight: () {
        final String? failure = cubit.addAnotherWeight(index);
        if (failure != null) ToastUtils.showInfo(context, failure);
      },
    );
  }
}

/// Totals for what is on the return so far, so the amount is visible before it
/// is submitted rather than only after.
class _Summary extends StatelessWidget {
  final ReturnOrderFormState state;

  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.summarize_outlined,
                size: AppSizes.ICON_MD,
                color: AppColors.PRIMARY,
              ),
              const SizedBox(width: AppSpacing.SM8),
              Text(
                AppStrings.RETURN_ORDER_DRAFT_SUMMARY,
                style: AppTypography.labelStrong,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.MD16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: AppStrings.RETURN_ORDER_TOTAL_PACKETS,
                  value: '${state.totalPackets}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: AppStrings.RETURN_ORDER_TOTAL_KG,
                  value: '${ReturnOrderItem.trimWeight(state.totalKg)} kg',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: AppStrings.RETURN_ORDER_TOTAL_AMOUNT,
                  value: CurrencyFormatter.rupees(state.totalAmount),
                  isEmphasised: true,
                ),
              ),
            ],
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
          style: AppTypography.caption.copyWith(color: AppColors.TEXT_DISABLED),
        ),
      ],
    );
  }
}

/// Why the screen is read-only: an order that never shipped, or one that
/// already has a return open. Said plainly rather than left as a dead form.
class _BlockedMessage extends StatelessWidget {
  final String reason;
  final String? liveReturnPublicId;

  const _BlockedMessage({required this.reason, this.liveReturnPublicId});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String title;
    late final String body;

    switch (reason) {
      case ReturnOrderFormBlockX.notReturnable:
        icon = Icons.block_outlined;
        title = AppStrings.RETURN_ORDER_BLOCK_NOT_RETURNABLE_TITLE;
        body = AppStrings.RETURN_ORDER_BLOCK_NOT_RETURNABLE_BODY;
      case ReturnOrderFormBlockX.liveReturn:
        icon = Icons.assignment_return_outlined;
        title = AppStrings.RETURN_ORDER_BLOCK_LIVE_RETURN_TITLE;
        // Naming the return is the point: the salesperson has to go and reject
        // or wait on that specific one.
        body = liveReturnPublicId == null || liveReturnPublicId!.isEmpty
            ? AppStrings.RETURN_ORDER_BLOCK_LIVE_RETURN_BODY
            : AppStrings.RETURN_ORDER_BLOCK_LIVE_RETURN_BODY.replaceAll(
                '%s',
                liveReturnPublicId!,
              );
      default:
        icon = Icons.inventory_2_outlined;
        title = AppStrings.RETURN_ORDER_BLOCK_NO_LINES_TITLE;
        body = AppStrings.RETURN_ORDER_BLOCK_NO_LINES_BODY;
    }

    return _Message(icon: icon, title: title, body: body);
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
            const SizedBox(height: AppSpacing.SMD12),
            Text(
              title,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.XS6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
