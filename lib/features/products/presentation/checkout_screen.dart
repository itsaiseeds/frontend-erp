import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_defaults.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/city_model.dart';
import '../../../core/models/country_model.dart';
import '../../../core/models/state_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/metadata_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/inputs/main_flag_toggle.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../auth/presentation/bloc/session_cubit.dart';
import '../../clients/data/clients_repository.dart';
import '../../clients/data/models/child_org.dart';
import '../../clients/data/models/client.dart';
import '../../clients/data/models/client_address.dart';
import '../../clients/data/models/sales_person_option.dart';
import '../../clients/data/models/transport_agency.dart';
import '../data/models/cart_line.dart';
import '../data/products_repository.dart';
import 'bloc/checkout_cubit.dart';
import 'bloc/checkout_state.dart';
import 'bloc/products_cubit.dart';
import 'bloc/products_state.dart';
import 'widgets/cart_line_tile.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = context.read<ApiClient>();
    final bool isAdmin =
        context.read<SessionCubit>().state.session?.isSalesAdmin ?? false;

    return BlocProvider<CheckoutCubit>(
      create: (_) => CheckoutCubit(
        clientsRepository: ClientsRepository(apiClient: apiClient),
        productsRepository: ProductsRepository(apiClient: apiClient),
        isAdmin: isAdmin,
      )..loadClients(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<CartLine> lines) async {
    final CheckoutCubit checkout = context.read<CheckoutCubit>();
    final ProductsCubit products = context.read<ProductsCubit>();

    FocusScope.of(context).unfocus();

    final bool placed = await checkout.placeOrder(lines);
    if (!mounted) return;

    if (!placed) {
      final String? message =
          checkout.state.validationMessage ?? checkout.state.errorMessage;
      if (message != null) ToastUtils.showError(context, message);
      return;
    }

    products.clearCart();
    Navigator.of(context).pop();
    ToastUtils.showSuccess(context, AppStrings.CART_ORDER_PLACED);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, productsState) {
        final List<CartLine> lines = productsState.cartLines;

        return BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) {
            final CheckoutCubit cubit = context.read<CheckoutCubit>();
            final bool isReview = state.step == CheckoutStep.review;

            return Scaffold(
              backgroundColor: AppColors.BACKGROUND,
              appBar: AppBar(
                backgroundColor: AppColors.SURFACE,
                surfaceTintColor: AppColors.TRANSPARENT,
                elevation: 0,
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
                      ? AppStrings.CART_TITLE
                      : AppStrings.CART_DELIVERY_TITLE,
                  style: AppTypography.titleMedium,
                ),
              ),
              body: lines.isEmpty
                  ? const _EmptyCart()
                  : DismissKeyboard(
                      child: isReview
                          ? _ReviewStep(
                              lines: lines,
                              total: productsState.cartTotal,
                            )
                          : _DeliveryStep(
                              state: state,
                              cubit: cubit,
                              commentsController: _commentsController,
                            ),
                    ),
              bottomNavigationBar: lines.isEmpty
                  ? null
                  : _Footer(
                      isReview: isReview,
                      state: state,
                      total: productsState.cartTotal,
                      itemCount: productsState.cartItemCount,
                      onContinue: cubit.goToDelivery,
                      onPlaceOrder: () => _placeOrder(lines),
                    ),
            );
          },
        );
      },
    );
  }
}

/// Step one: the shipment, exactly what is being ordered.
class _ReviewStep extends StatelessWidget {
  final List<CartLine> lines;
  final num total;

  const _ReviewStep({required this.lines, required this.total});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShipmentHeader(itemCount: lines.length),
              for (int index = 0; index < lines.length; index++) ...[
                if (index > 0) const _LineSeparator(),
                CartLineTile(
                  line: lines[index],
                  onAdd: () => context.read<ProductsCubit>().addToCart(
                    lines[index].packaging,
                  ),
                  onRemove: () => context.read<ProductsCubit>().removeFromCart(
                    lines[index].packaging,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Between products only -- a rule above the first line would cut it off from
/// the shipment header it belongs to. Inset past the thumbnail so it lines up
/// with the product text.
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

  const _ShipmentHeader({required this.itemCount});

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
        ],
      ),
    );
  }
}

/// Step two: who it goes to and how.
class _DeliveryStep extends StatelessWidget {
  final CheckoutState state;
  final CheckoutCubit cubit;
  final TextEditingController commentsController;

  const _DeliveryStep({
    required this.state,
    required this.cubit,
    required this.commentsController,
  });

  /// The picker needs a real item meaning "no one chosen" -- id 0 is never a
  /// valid sales person, matching how [TransportAgency.PRIVATE_DISPATCH] sits
  /// in the agency list below for the same reason.
  static const SalesPersonOption _bookForSelf = SalesPersonOption(
    id: 0,
    name: AppStrings.CART_BOOK_FOR_SELF,
  );

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
                if (state.isAdmin) ...[
                  GeoPickerField<SalesPersonOption>(
                    label: AppStrings.CART_BOOK_FOR,
                    hint: AppStrings.CART_BOOK_FOR_HINT,
                    value: state.bookingFor ?? _bookForSelf,
                    items: [_bookForSelf, ...state.salesPersons],
                    itemLabel: (person) => person.name,
                    isSame: (a, b) => a.id == b.id,
                    onSelected: (person) => cubit.selectSalesPerson(
                      person.id == 0 ? null : person,
                    ),
                    enabled: !state.isLoadingSalesPersons && !state.isSubmitting,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                ],
                GeoPickerField<Client>(
                  label: AppStrings.CART_SELECT_CLIENT,
                  hint: AppStrings.CART_SELECT_CLIENT_HINT,
                  value: state.client,
                  items: state.clients,
                  itemLabel: (client) => client.companyName,
                  isSame: (a, b) => a.publicId == b.publicId,
                  onSelected: cubit.selectClient,
                  enabled: !state.isLoading && !state.isSubmitting,
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.MD16),
                GeoPickerField<ClientAddress>(
                  label: AppStrings.CART_SELECT_ADDRESS,
                  hint: AppStrings.CART_SELECT_ADDRESS_HINT,
                  value: state.address,
                  items: state.addresses,
                  itemLabel: _addressLabel,
                  isSame: (a, b) => a.id == b.id,
                  onSelected: cubit.selectAddress,
                  enabled:
                      state.addresses.isNotEmpty &&
                      !state.isLoadingLinks &&
                      !state.isSubmitting,
                  disabledHint: _optionsHint(
                    state,
                    AppStrings.CART_NO_ADDRESSES,
                  ),
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.MD16),
                _DeliverElsewhereSection(state: state, cubit: cubit),
                const SizedBox(height: AppSpacing.MD16),
                GeoPickerField<TransportAgency>(
                  label: AppStrings.CART_SELECT_AGENCY,
                  hint: AppStrings.CART_SELECT_AGENCY_HINT,
                  value: state.agency,
                  items: state.agencies,
                  itemLabel: (agency) => agency.name,
                  isSame: (a, b) => a.id == b.id,
                  onSelected: cubit.selectAgency,
                  // Private dispatch is always in the list, so this picker
                  // never closes for lack of a saved agency.
                  enabled:
                      state.agencies.isNotEmpty &&
                      !state.isLoadingLinks &&
                      !state.isSubmitting,
                  disabledHint: _optionsHint(
                    state,
                    AppStrings.CART_SELECT_AGENCY_HINT,
                  ),
                ),
                const SizedBox(height: AppSpacing.MD16),
                AppTextField(
                  controller: commentsController,
                  label: AppStrings.CART_COMMENTS,
                  hint: AppStrings.CART_COMMENTS_HINT,
                  maxLines: 3,
                  enabled: !state.isSubmitting,
                  onChanged: cubit.updateComments,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Why a picker is closed: no client yet, links still loading, or the client
  /// genuinely has none saved.
  static String _optionsHint(CheckoutState state, String emptyHint) {
    if (state.client == null) return AppStrings.CART_SELECT_CLIENT_HINT;
    if (state.isLoadingLinks) return AppStrings.CART_LOADING_OPTIONS;
    return emptyHint;
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

/// The optional "Delivery To" section: a plain toggle that, switched on,
/// reveals either a picker over the client's existing delivery places or an
/// inline form for a brand-new one -- all inside the same delivery card, so
/// booking never leaves this screen.
class _DeliverElsewhereSection extends StatelessWidget {
  final CheckoutState state;
  final CheckoutCubit cubit;

  const _DeliverElsewhereSection({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final bool hasClient = state.client != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MainFlagToggle(
          value: state.deliversElsewhere,
          enabled: hasClient && !state.isSubmitting,
          label: AppStrings.CART_DELIVER_ELSEWHERE,
          hint: hasClient
              ? AppStrings.CART_DELIVER_ELSEWHERE_HINT
              : AppStrings.CART_DELIVER_ELSEWHERE_LOCKED,
          onChanged: cubit.setDeliversElsewhere,
        ),
        if (state.deliversElsewhere) ...[
          const SizedBox(height: AppSpacing.MD16),
          _DeliveryPlacePicker(state: state, cubit: cubit),
        ],
      ],
    );
  }
}

class _DeliveryPlacePicker extends StatelessWidget {
  final CheckoutState state;
  final CheckoutCubit cubit;

  const _DeliveryPlacePicker({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    if (state.isAddingNewDeliveryPlace) {
      return _NewDeliveryPlaceForm(state: state, cubit: cubit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GeoPickerField<ChildOrg>(
          label: AppStrings.CART_DELIVERY_PLACE,
          hint: state.isLoadingDeliveryPlaces
              ? AppStrings.CART_LOADING_OPTIONS
              : AppStrings.CART_DELIVERY_PLACE_HINT,
          value: state.deliveryPlace,
          items: state.deliveryPlaces,
          itemLabel: (place) => place.label,
          isSame: (a, b) => a.id == b.id,
          onSelected: cubit.selectDeliveryPlace,
          enabled: state.deliveryPlaces.isNotEmpty && !state.isSubmitting,
          disabledHint: state.isLoadingDeliveryPlaces
              ? AppStrings.CART_LOADING_OPTIONS
              : AppStrings.CART_DELIVERY_PLACE_HINT,
          isRequired: true,
        ),
        const SizedBox(height: AppSpacing.SM8),
        GestureDetector(
          onTap: state.isSubmitting ? null : cubit.startNewDeliveryPlace,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_circle_outline_rounded,
                size: AppSizes.ICON_MD,
                color: AppColors.PRIMARY,
              ),
              const SizedBox(width: AppSpacing.XS6),
              Text(
                AppStrings.CART_DELIVERY_PLACE_ADD_NEW,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.PRIMARY,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The inline "new delivery place" form: party/village, the same address
/// fields `AddressEditor` uses for a client's own address, then optional
/// transport/contact. Kept inline (not a pushed screen) so booking stays in
/// one flow.
class _NewDeliveryPlaceForm extends StatefulWidget {
  final CheckoutState state;
  final CheckoutCubit cubit;

  const _NewDeliveryPlaceForm({required this.state, required this.cubit});

  @override
  State<_NewDeliveryPlaceForm> createState() => _NewDeliveryPlaceFormState();
}

class _NewDeliveryPlaceFormState extends State<_NewDeliveryPlaceForm> {
  late final TextEditingController _partyController;
  late final TextEditingController _villageController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _pincodeController;
  late final TextEditingController _transportController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final NewDeliveryPlaceDraft draft = widget.state.newDeliveryPlace;
    _partyController = TextEditingController(text: draft.partyName);
    _villageController = TextEditingController(text: draft.villageName);
    _line1Controller = TextEditingController(text: draft.line1);
    _line2Controller = TextEditingController(text: draft.line2);
    _pincodeController = TextEditingController(text: draft.pincode);
    _transportController = TextEditingController(text: draft.transportName);
    _contactController = TextEditingController(text: draft.contactNumber);

    // The country picker shows a default when none is picked yet (so the
    // field never looks empty), but that default has to actually land in the
    // draft -- otherwise the form reads as complete while `isComplete` still
    // sees a null country and "Place order" stays disabled forever.
    if (draft.country == null) {
      final CountryModel? fallback = _defaultCountry(
        MetadataService.instance.countries,
      );
      if (fallback != null) {
        _update((current) => current.copyWith(country: fallback));
      }
    }
  }

  @override
  void dispose() {
    _partyController.dispose();
    _villageController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _pincodeController.dispose();
    _transportController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  NewDeliveryPlaceDraft get _draft => widget.state.newDeliveryPlace;

  void _update(NewDeliveryPlaceDraft Function(NewDeliveryPlaceDraft) change) {
    widget.cubit.updateNewDeliveryPlace(change(_draft));
  }

  @override
  Widget build(BuildContext context) {
    final bool isSubmitting = widget.state.isSubmitting;
    final CountryModel? country =
        _draft.country ?? _defaultCountry(MetadataService.instance.countries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _partyController,
          label: AppStrings.CART_DELIVERY_PLACE_PARTY_NAME,
          hint: AppStrings.CART_DELIVERY_PLACE_PARTY_NAME_HINT,
          isRequired: true,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              _update((draft) => draft.copyWith(partyName: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        AppTextField(
          controller: _villageController,
          label: AppStrings.CART_DELIVERY_PLACE_VILLAGE,
          hint: AppStrings.CART_DELIVERY_PLACE_VILLAGE_HINT,
          isRequired: true,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              _update((draft) => draft.copyWith(villageName: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        AppTextField(
          controller: _line1Controller,
          label: AppStrings.CLIENT_FIELD_LINE1,
          hint: AppStrings.CLIENT_FIELD_LINE1_HINT,
          isRequired: true,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              _update((draft) => draft.copyWith(line1: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        AppTextField(
          controller: _line2Controller,
          label: AppStrings.CLIENT_FIELD_LINE2,
          hint: AppStrings.CLIENT_FIELD_LINE2_HINT,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              _update((draft) => draft.copyWith(line2: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        GeoPickerField<CountryModel>(
          label: AppStrings.CLIENT_FIELD_COUNTRY,
          hint: AppStrings.CLIENT_FIELD_COUNTRY_HINT,
          value: country,
          items: MetadataService.instance.countries,
          itemLabel: (item) => item.name,
          isSame: (a, b) => a.id == b.id,
          isRequired: true,
          enabled: !isSubmitting,
          onSelected: (value) => _update(
            (draft) => draft.copyWith(
              country: value,
              clearState: draft.country?.id != value.id,
              clearCity: draft.country?.id != value.id,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        GeoPickerField<StateModel>(
          label: AppStrings.CLIENT_FIELD_STATE,
          hint: AppStrings.CLIENT_FIELD_STATE_HINT,
          value: _draft.state,
          items: MetadataService.instance.statesInCountry(country?.id),
          itemLabel: (item) => item.name,
          isSame: (a, b) => a.id == b.id,
          isRequired: true,
          enabled: !isSubmitting && country != null,
          disabledHint: AppStrings.CLIENT_FIELD_STATE_LOCKED,
          onSelected: (value) => _update(
            (draft) => draft.copyWith(
              state: value,
              clearCity: draft.state?.id != value.id,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        GeoPickerField<CityModel>(
          label: AppStrings.CLIENT_FIELD_CITY,
          hint: AppStrings.CLIENT_FIELD_CITY_HINT,
          value: _draft.city,
          items: MetadataService.instance.citiesInState(_draft.state?.id),
          itemLabel: (item) => item.name,
          isSame: (a, b) => a.id == b.id,
          isRequired: true,
          enabled: !isSubmitting && _draft.state != null,
          disabledHint: AppStrings.CLIENT_FIELD_CITY_LOCKED,
          onSelected: (value) => _update((draft) => draft.copyWith(city: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        AppTextField(
          controller: _pincodeController,
          label: AppStrings.CLIENT_FIELD_PINCODE,
          keyboardType: TextInputType.number,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppValidators.PINCODE_LENGTH),
          ],
          onChanged: (value) =>
              _update((draft) => draft.copyWith(pincode: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        AppTextField(
          controller: _transportController,
          label: AppStrings.CART_DELIVERY_PLACE_TRANSPORT,
          hint: AppStrings.CART_DELIVERY_PLACE_TRANSPORT_HINT,
          enabled: !isSubmitting,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              _update((draft) => draft.copyWith(transportName: value)),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        AppTextField(
          controller: _contactController,
          label: AppStrings.CART_DELIVERY_PLACE_CONTACT,
          hint: AppStrings.LOGIN_PHONE_HINT,
          prefixText: AppStrings.PHONE_COUNTRY_CODE_IN,
          enabled: !isSubmitting,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppValidators.PHONE_LENGTH),
          ],
          onChanged: (value) =>
              _update((draft) => draft.copyWith(contactNumber: value)),
        ),
        if (widget.state.deliveryPlaces.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.SM8),
          GestureDetector(
            onTap: isSubmitting ? null : widget.cubit.useExistingDeliveryPlace,
            behavior: HitTestBehavior.opaque,
            child: Text(
              AppStrings.CART_DELIVERY_PLACE_USE_EXISTING,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.PRIMARY,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static CountryModel? _defaultCountry(List<CountryModel> countries) {
    if (countries.length == 1) return countries.first;
    for (final CountryModel country in countries) {
      if (country.id == AppDefaults.COUNTRY_ID) return country;
    }
    return null;
  }
}

/// Review shows a Continue action; delivery reveals the chosen address and the
/// order total once there is something to confirm.
class _Footer extends StatelessWidget {
  final bool isReview;
  final CheckoutState state;
  final num total;
  final int itemCount;
  final VoidCallback onContinue;
  final VoidCallback onPlaceOrder;

  const _Footer({
    required this.isReview,
    required this.state,
    required this.total,
    required this.itemCount,
    required this.onContinue,
    required this.onPlaceOrder,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isReview && state.isDeliveryResolved)
              _DeliveryRow(address: state.address!),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.MD16),
              child: isReview
                  ? _ActionButton(
                      label: AppStrings.CART_CONTINUE,
                      total: total,
                      onTap: onContinue,
                    )
                  : _ActionButton(
                      label: AppStrings.CART_PLACE_ORDER,
                      total: total,
                      isLoading: state.isSubmitting,
                      onTap: state.canSubmit ? onPlaceOrder : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final ClientAddress address;

  const _DeliveryRow({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.MD16,
        AppSpacing.SMD12,
        AppSpacing.MD16,
        0,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: AppSizes.ICON_LG,
            color: AppColors.PRIMARY,
          ),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.CART_DELIVERING_TO,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  address.formatted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_PRIMARY,
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: AppSizes.ICON_XXL,
              color: AppColors.TEXT_DISABLED,
            ),
            const SizedBox(height: AppSpacing.SMD12),
            Text(AppStrings.CART_EMPTY_TITLE, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.XS6),
            Text(
              AppStrings.CART_EMPTY_BODY,
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
