import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/inputs/main_flag_toggle.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../clients/data/clients_repository.dart';
import '../../clients/data/models/child_org.dart';
import '../../clients/data/models/client_address.dart';
import '../../clients/data/models/transport_agency.dart';
import '../../products/data/models/cart_line.dart';
import '../../products/presentation/widgets/cart_line_tile.dart';
import '../data/models/order.dart';
import '../data/orders_repository.dart';
import 'bloc/edit_order_cubit.dart';
import 'bloc/edit_order_state.dart';
import 'widgets/add_products_dialog.dart';

/// Edits one of the caller's own BOOKED orders, in the same two-step shape as
/// booking a fresh one (`checkout_screen.dart`): review the (pre-filled)
/// cart, then the delivery details, then save. Only a BOOKED order can reach
/// this screen -- see `OrderStatusX.isEditable` and the Edit action on
/// `order_detail_screen.dart`.
///
/// There is no `OrdersCubit` in scope here (`OrderDetailScreen`, this
/// screen's own caller, is pushed without one) -- so a save pops `true`
/// rather than refreshing a list directly, and whoever opened this screen is
/// responsible for passing that along to whoever can refresh.
class EditOrderScreen extends StatelessWidget {
  final Order order;

  const EditOrderScreen({super.key, required this.order});

  /// Opens the screen and answers whether it saved a change, so the caller
  /// can refresh whatever order list it is showing.
  static Future<bool?> open(BuildContext context, Order order) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EditOrderScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = context.read<ApiClient>();

    return BlocProvider<EditOrderCubit>(
      create: (_) => EditOrderCubit(
        clientsRepository: ClientsRepository(apiClient: apiClient),
        ordersRepository: OrdersRepository(apiClient: apiClient),
        order: order,
      )..loadLinks(),
      child: const _EditOrderView(),
    );
  }
}

class _EditOrderView extends StatefulWidget {
  const _EditOrderView();

  @override
  State<_EditOrderView> createState() => _EditOrderViewState();
}

class _EditOrderViewState extends State<_EditOrderView> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final EditOrderCubit cubit = context.read<EditOrderCubit>();

    FocusScope.of(context).unfocus();

    final bool saved = await cubit.submit();
    if (!mounted) return;

    if (!saved) {
      final String? message =
          cubit.state.validationMessage ?? cubit.state.errorMessage;
      if (message != null) ToastUtils.showError(context, message);
      return;
    }

    Navigator.of(context).pop(true);
    ToastUtils.showSuccess(context, AppStrings.EDIT_ORDER_SAVED);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditOrderCubit, EditOrderState>(
      builder: (context, state) {
        final EditOrderCubit cubit = context.read<EditOrderCubit>();
        final bool isReview = state.step == EditOrderStep.review;

        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          appBar: AppBar(
            backgroundColor: AppColors.SURFACE,
            surfaceTintColor: AppColors.TRANSPARENT,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              onPressed: () {
                if (isReview) {
                  Navigator.of(context).pop();
                  return;
                }
                cubit.backToReview();
              },
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: AppSizes.ICON_XL,
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
            title: Text(
              isReview
                  ? AppStrings.EDIT_ORDER_TITLE
                  : AppStrings.EDIT_ORDER_DELIVERY_TITLE,
              style: AppTypography.titleMedium,
            ),
          ),
          body: DismissKeyboard(
            child: isReview
                ? _ReviewStep(state: state, cubit: cubit)
                : _DeliveryStep(
                    state: state,
                    cubit: cubit,
                    commentController: _commentController,
                  ),
          ),
          bottomNavigationBar: _Footer(
            isReview: isReview,
            state: state,
            onContinue: cubit.goToDelivery,
            onSave: _save,
          ),
        );
      },
    );
  }
}

/// Step one: the cart, pre-filled from the order's own lines and restepped
/// exactly like a fresh booking's review step. The "+" on the header opens
/// the full catalogue so items can be added -- something a fresh booking
/// gets by browsing first, but an edit has no browse step of its own to
/// return to.
class _ReviewStep extends StatelessWidget {
  final EditOrderState state;
  final EditOrderCubit cubit;

  const _ReviewStep({required this.state, required this.cubit});

  Future<void> _addProducts(BuildContext context) async {
    final List<CartLine>? result = await AddProductsDialog.show(
      context,
      initialLines: state.lines,
    );
    if (result == null) return;
    cubit.setLines(result);
  }

  @override
  Widget build(BuildContext context) {
    final List<CartLine> lines = state.lines;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SMD12,
        AppSpacing.SMD12,
        AppSpacing.LG24,
      ),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShipmentHeader(
                itemCount: lines.length,
                onAddProducts: () => _addProducts(context),
              ),
              if (lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.MD16,
                    0,
                    AppSpacing.MD16,
                    AppSpacing.MD16,
                  ),
                  child: Text(AppStrings.VALIDATION_LINES_REQUIRED),
                )
              else
                for (int index = 0; index < lines.length; index++) ...[
                  if (index > 0) const _LineSeparator(),
                  CartLineTile(
                    line: lines[index],
                    onAdd: () => cubit.addLine(lines[index].packaging),
                    onRemove: () => cubit.removeLine(lines[index].packaging),
                    onSet: (quantity) =>
                        cubit.setLineQuantity(lines[index].packaging, quantity),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LineSeparator extends StatelessWidget {
  const _LineSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: AppSizes.CART_SEPARATOR_INSET,
        right: AppSpacing.MD16,
      ),
      child: Divider(
        height: AppSizes.DIVIDER_THIN,
        thickness: AppSizes.DIVIDER_THIN,
        color: AppColors.DIVIDER,
      ),
    );
  }
}

class _ShipmentHeader extends StatelessWidget {
  final int itemCount;
  final VoidCallback onAddProducts;

  const _ShipmentHeader({required this.itemCount, required this.onAddProducts});

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
          Container(
            width: AppSizes.CHECKOUT_ICON_BOX,
            height: AppSizes.CHECKOUT_ICON_BOX,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.PRIMARY_SURFACE,
              borderRadius: BorderRadius.circular(AppRadius.MD),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: AppSizes.ICON_LG,
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
                  AppStrings.CART_SHIPMENT_TITLE,
                  style: AppTypography.labelStrong.copyWith(
                    color: AppColors.TEXT_PRIMARY,
                  ),
                ),
                Text(
                  '${AppStrings.CART_SHIPMENT_OF} $itemCount '
                  '${itemCount == 1 ? AppStrings.CART_ITEM : AppStrings.CART_ITEMS}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.SM8),
          _AddProductsButton(onTap: onAddProducts),
        ],
      ),
    );
  }
}

/// A circular "+" beside the shipment summary -- opens the full catalogue
/// (`AddProductsDialog`) to add items that were not on the order originally.
class _AddProductsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.EDIT_ORDER_ADD_PRODUCTS,
      child: Material(
        color: AppColors.PRIMARY,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSizes.CHECKOUT_ICON_BOX,
            height: AppSizes.CHECKOUT_ICON_BOX,
            child: const Icon(
              Icons.add_rounded,
              size: AppSizes.ICON_LG,
              color: AppColors.TEXT_ON_PRIMARY,
            ),
          ),
        ),
      ),
    );
  }
}

/// Step two: address, agency, "deliver elsewhere" and a note -- the same
/// fields checkout's delivery step shows, minus the client picker (an
/// order's client cannot change) and the "add a new delivery place" form
/// (editing picks among the client's existing places only).
class _DeliveryStep extends StatelessWidget {
  final EditOrderState state;
  final EditOrderCubit cubit;
  final TextEditingController commentController;

  const _DeliveryStep({
    required this.state,
    required this.cubit,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.SMD12,
        AppSpacing.SMD12,
        AppSpacing.SMD12,
        AppSpacing.LG24,
      ),
      children: [
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ClientRow(name: state.order.client.companyName),
                const SizedBox(height: AppSpacing.MD16),
                GeoPickerField<ClientAddress>(
                  label: AppStrings.CART_SELECT_ADDRESS,
                  hint: state.order.deliveryAddress.isEmpty
                      ? AppStrings.CART_SELECT_ADDRESS_HINT
                      : state.order.deliveryAddress,
                  value: state.address,
                  items: state.addresses,
                  itemLabel: _addressLabel,
                  isSame: (a, b) => a.id == b.id,
                  onSelected: cubit.selectAddress,
                  enabled:
                      state.addresses.isNotEmpty &&
                      !state.isLoadingLinks &&
                      !state.isSubmitting,
                  disabledHint: state.isLoadingLinks
                      ? AppStrings.CART_LOADING_OPTIONS
                      : AppStrings.CART_NO_ADDRESSES,
                ),
                const SizedBox(height: AppSpacing.MD16),
                _DeliverElsewhereSection(state: state, cubit: cubit),
                const SizedBox(height: AppSpacing.MD16),
                GeoPickerField<TransportAgency>(
                  label: AppStrings.CART_SELECT_AGENCY,
                  hint: state.order.isAgencyDispatch
                      ? AppStrings.ORDER_DISPATCH_AGENCY
                      : AppStrings.ORDER_DISPATCH_PRIVATE,
                  value: state.agency,
                  items: state.agencies,
                  itemLabel: (agency) => agency.name,
                  isSame: (a, b) => a.id == b.id,
                  onSelected: cubit.selectAgency,
                  enabled:
                      state.agencies.isNotEmpty &&
                      !state.isLoadingLinks &&
                      !state.isSubmitting,
                  disabledHint: state.isLoadingLinks
                      ? AppStrings.CART_LOADING_OPTIONS
                      : AppStrings.CART_SELECT_AGENCY_HINT,
                ),
                const SizedBox(height: AppSpacing.MD16),
                AppTextField(
                  controller: commentController,
                  label: AppStrings.EDIT_ORDER_COMMENT_LABEL,
                  hint: AppStrings.EDIT_ORDER_COMMENT_HINT,
                  maxLines: 3,
                  enabled: !state.isSubmitting,
                  onChanged: cubit.updateComment,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _addressLabel(ClientAddress address) {
    final List<String> parts = [
      address.label,
      address.line1,
      address.cityName,
      address.pincode,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    return parts.join(', ');
  }
}

/// The order's client, shown read-only -- it cannot change on an edit.
class _ClientRow extends StatelessWidget {
  final String name;

  const _ClientRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.CART_SELECT_CLIENT,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
        const SizedBox(height: AppSpacing.XXS2),
        Text(name, style: AppTypography.labelMedium),
      ],
    );
  }
}

/// The optional "Delivery To" section, limited (unlike checkout's) to the
/// client's existing places -- editing is a correction, not a place to set
/// up a brand-new one.
class _DeliverElsewhereSection extends StatelessWidget {
  final EditOrderState state;
  final EditOrderCubit cubit;

  const _DeliverElsewhereSection({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MainFlagToggle(
          value: state.deliversElsewhere,
          enabled: !state.isSubmitting,
          label: AppStrings.CART_DELIVER_ELSEWHERE,
          hint: AppStrings.CART_DELIVER_ELSEWHERE_HINT,
          onChanged: cubit.setDeliversElsewhere,
        ),
        if (state.deliversElsewhere) ...[
          const SizedBox(height: AppSpacing.MD16),
          GeoPickerField<ChildOrg>(
            label: AppStrings.CART_DELIVERY_PLACE,
            hint: state.order.bookedFor?.label ??
                AppStrings.CART_DELIVERY_PLACE_HINT,
            value: state.deliveryPlace,
            items: state.deliveryPlaces,
            itemLabel: (place) => place.label,
            isSame: (a, b) => a.id == b.id,
            onSelected: cubit.selectDeliveryPlace,
            enabled: state.deliveryPlaces.isNotEmpty && !state.isSubmitting,
            disabledHint: state.isLoadingDeliveryPlaces
                ? AppStrings.CART_LOADING_OPTIONS
                : AppStrings.CART_DELIVERY_PLACE_HINT,
          ),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isReview;
  final EditOrderState state;
  final VoidCallback onContinue;
  final VoidCallback onSave;

  const _Footer({
    required this.isReview,
    required this.state,
    required this.onContinue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.SURFACE,
        border: Border(top: BorderSide(color: AppColors.BORDER)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.MD16),
          child: isReview
              ? _ActionButton(
                  label: AppStrings.CART_CONTINUE,
                  total: state.linesTotal,
                  onTap: state.lines.isNotEmpty ? onContinue : null,
                )
              : _ActionButton(
                  label: AppStrings.EDIT_ORDER_SAVE,
                  total: state.linesTotal,
                  isLoading: state.isSubmitting,
                  onTap: state.canSubmit ? onSave : null,
                ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final num total;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.total,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null && !isLoading;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppSizes.CHECKOUT_ACTION_HEIGHT,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.PRIMARY : AppColors.TEXT_DISABLED,
          borderRadius: BorderRadius.circular(AppRadius.LG),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyFormatter.rupees(total),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.TEXT_ON_PRIMARY,
                    ),
                  ),
                  Text(
                    AppStrings.CART_TOTAL.toUpperCase(),
                    style: AppTypography.overline.copyWith(
                      color: AppColors.TEXT_ON_PRIMARY_MUTED,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: AppSizes.ICON_LG,
                height: AppSizes.ICON_LG,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.BORDER_MEDIUM,
                  color: AppColors.TEXT_ON_PRIMARY,
                ),
              )
            else ...[
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.TEXT_ON_PRIMARY,
                ),
              ),
              const SizedBox(width: AppSpacing.XS6),
              const Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.ICON_LG,
                color: AppColors.TEXT_ON_PRIMARY,
              ),
            ],
          ],
        ),
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
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
