import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/godown_repository.dart';
import '../data/models/godown_pickable.dart';
import 'bloc/inward_raw_cubit.dart';

class InwardRawFormScreen extends StatefulWidget {
  const InwardRawFormScreen({super.key});

  static Future<bool?> push(
    BuildContext context, {
    required InwardRawCubit cubit,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider<InwardRawCubit>.value(
          value: cubit,
          child: const InwardRawFormScreen(),
        ),
      ),
    );
  }

  @override
  State<InwardRawFormScreen> createState() => _InwardRawFormScreenState();
}

class _InwardRawFormScreenState extends State<InwardRawFormScreen> {
  final TextEditingController _lotNoController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _farmerController = TextEditingController();

  GodownPickableProduct? _product;
  GodownPickableParty? _party;
  DateTime? _labSamplingDate;

  List<GodownPickableProduct> _products = const [];
  List<GodownPickableParty> _parties = const [];

  String? _productError;
  String? _partyError;
  String? _lotNoError;
  String? _quantityError;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labSamplingDate = DateTime.now();
    _loadLookups();
  }

  @override
  void dispose() {
    _lotNoController.dispose();
    _quantityController.dispose();
    _farmerController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final GodownRepository repository = GodownRepository(
      apiClient: context.read<ApiClient>(),
    );
    try {
      final List<GodownPickableProduct> products = await repository
          .fetchUsableProducts();
      final List<GodownPickableParty> parties = await repository.fetchParties(
        partyType: GodownPartyType.rawMaterial,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _parties = parties;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastUtils.showServerError(context, error.message);
    }
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _labSamplingDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.PRIMARY,
              onPrimary: AppColors.TEXT_ON_PRIMARY,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _labSamplingDate = picked);
  }

  bool _validate() {
    final String quantity = _quantityController.text.trim();
    final double? value = double.tryParse(quantity);

    setState(() {
      _productError = _product == null
          ? AppStrings.INWARD_VALIDATION_PRODUCT
          : null;
      _partyError = _party == null ? AppStrings.INWARD_VALIDATION_PARTY : null;
      _lotNoError = _lotNoController.text.trim().isEmpty
          ? AppStrings.INWARD_VALIDATION_LOT_NO
          : null;
      _quantityError = quantity.isEmpty || value == null
          ? AppStrings.INWARD_VALIDATION_QUANTITY
          : (value <= 0
                ? AppStrings.INWARD_VALIDATION_QUANTITY_POSITIVE
                : null);
    });

    return _productError == null &&
        _partyError == null &&
        _lotNoError == null &&
        _quantityError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;
    setState(() => _isSaving = true);

    final bool succeeded = await context.read<InwardRawCubit>().bookLot(
      productPublicId: _product!.publicId,
      partyId: _party!.id,
      lotNo: _lotNoController.text,
      quantityKg: _quantityController.text.trim(),
      farmerName: _farmerController.text.trim(),
      labSamplingDate: _labSamplingDate,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (succeeded) {
      ToastUtils.showSuccess(context, AppStrings.INWARD_BOOKED_RAW);
      Navigator.of(context).pop(true);
      return;
    }
    ToastUtils.showServerError(
      context,
      context.read<InwardRawCubit>().state.errorMessage ??
          AppStrings.SOMETHING_WENT_WRONG,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUND,
        appBar: AppBar(
          backgroundColor: AppColors.SURFACE,
          surfaceTintColor: AppColors.TRANSPARENT,
          elevation: 0,
          titleSpacing: 0,
          leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: AppSizes.ICON_XL,
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
          title: Text(
            AppStrings.INWARD_BOOK_RAW,
            style: AppTypography.titleMedium,
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.PRIMARY),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.MD16),
                children: [
                  GeoPickerField<GodownPickableProduct>(
                    label: AppStrings.INWARD_FIELD_PRODUCT,
                    hint: AppStrings.INWARD_FIELD_PRODUCT_HINT,
                    value: _product,
                    items: _products,
                    itemLabel: (product) => product.name,
                    isSame: (a, b) => a.publicId == b.publicId,
                    isRequired: true,
                    errorText: _productError,
                    onSelected: (product) => setState(() {
                      _product = product;
                      _productError = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  GeoPickerField<GodownPickableParty>(
                    label: AppStrings.INWARD_FIELD_PARTY,
                    hint: AppStrings.INWARD_FIELD_PARTY_HINT,
                    value: _party,
                    items: _parties,
                    itemLabel: (party) => party.label,
                    isSame: (a, b) => a.id == b.id,
                    isRequired: true,
                    errorText: _partyError,
                    onSelected: (party) => setState(() {
                      _party = party;
                      _partyError = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _lotNoController,
                    label: AppStrings.INWARD_FIELD_LOT_NO,
                    hint: AppStrings.INWARD_FIELD_LOT_NO_HINT,
                    errorText: _lotNoError,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_lotNoError != null) {
                        setState(() => _lotNoError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _farmerController,
                    label: AppStrings.INWARD_FIELD_FARMER_NAME,
                    hint: AppStrings.INWARD_FIELD_FARMER_NAME_HINT,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _quantityController,
                    label: AppStrings.INWARD_FIELD_QUANTITY_KG,
                    hint: AppStrings.INWARD_FIELD_QUANTITY_KG_HINT,
                    errorText: _quantityError,
                    isRequired: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,3}'),
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_quantityError != null) {
                        setState(() => _quantityError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  _DateField(
                    label: AppStrings.INWARD_FIELD_LAB_SAMPLING_DATE,
                    value: _labSamplingDate,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: AppSpacing.XL32),
                  _SaveButton(isLoading: _isSaving, onPressed: _save),
                ],
              ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: AppSpacing.SM8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.LG),
          child: Container(
            height: AppSizes.BUTTON_HEIGHT,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.BORDER),
              borderRadius: BorderRadius.circular(AppRadius.LG),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.ICON_MD,
                  color: AppColors.TEXT_SECONDARY,
                ),
                const SizedBox(width: AppSpacing.SM8),
                Text(DateFormatter.day(value), style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SaveButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLoading ? AppColors.PRIMARY_LIGHT : AppColors.PRIMARY,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.LG),
        child: Container(
          height: AppSizes.BUTTON_HEIGHT,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: AppSizes.ICON_LG,
                  height: AppSizes.ICON_LG,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.BORDER_MEDIUM,
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                )
              : Text(
                  AppStrings.INWARD_BOOK_RAW,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
        ),
      ),
    );
  }
}
