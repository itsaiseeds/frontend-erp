import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/godown_repository.dart';
import '../data/models/godown_pickable.dart';
import 'bloc/raw_material_waste_cubit.dart';

/// Records waste against a product's raw-material pool. There is no party or
/// date -- waste is a standing deduction from the moment it is recorded, not
/// something received from anywhere.
class RawMaterialWasteFormScreen extends StatefulWidget {
  const RawMaterialWasteFormScreen({super.key});

  static Future<bool?> push(
    BuildContext context, {
    required RawMaterialWasteCubit cubit,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider<RawMaterialWasteCubit>.value(
          value: cubit,
          child: const RawMaterialWasteFormScreen(),
        ),
      ),
    );
  }

  @override
  State<RawMaterialWasteFormScreen> createState() =>
      _RawMaterialWasteFormScreenState();
}

class _RawMaterialWasteFormScreenState
    extends State<RawMaterialWasteFormScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  GodownPickableProduct? _product;
  List<GodownPickableProduct> _products = const [];

  String? _productError;
  String? _quantityError;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final GodownRepository repository = GodownRepository(
      apiClient: context.read<ApiClient>(),
    );
    try {
      final List<GodownPickableProduct> products = await repository
          .fetchUsableProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastUtils.showServerError(context, error.message);
    }
  }

  bool _validate() {
    final String quantity = _quantityController.text.trim();
    final double? value = double.tryParse(quantity);

    setState(() {
      _productError = _product == null
          ? AppStrings.WASTE_VALIDATION_PRODUCT
          : null;
      _quantityError = quantity.isEmpty || value == null
          ? AppStrings.WASTE_VALIDATION_QUANTITY
          : (value <= 0 ? AppStrings.WASTE_VALIDATION_QUANTITY_POSITIVE : null);
    });

    return _productError == null && _quantityError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;
    setState(() => _isSaving = true);

    final bool succeeded = await context.read<RawMaterialWasteCubit>().recordWaste(
      productPublicId: _product!.publicId,
      quantityKg: _quantityController.text.trim(),
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (succeeded) {
      ToastUtils.showSuccess(context, AppStrings.WASTE_RECORDED);
      Navigator.of(context).pop(true);
      return;
    }
    ToastUtils.showServerError(
      context,
      context.read<RawMaterialWasteCubit>().state.errorMessage ??
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
            AppStrings.WASTE_ADD_TITLE,
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
                    label: AppStrings.WASTE_FIELD_PRODUCT,
                    hint: AppStrings.WASTE_FIELD_PRODUCT_HINT,
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
                  AppTextField(
                    controller: _quantityController,
                    label: AppStrings.WASTE_FIELD_QUANTITY_KG,
                    hint: AppStrings.WASTE_FIELD_QUANTITY_KG_HINT,
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
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_quantityError != null) {
                        setState(() => _quantityError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _reasonController,
                    label: AppStrings.WASTE_FIELD_REASON,
                    hint: AppStrings.WASTE_FIELD_REASON_HINT,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(255)],
                  ),
                  const SizedBox(height: AppSpacing.XL32),
                  _SaveButton(isLoading: _isSaving, onPressed: _save),
                ],
              ),
      ),
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
                  AppStrings.WASTE_ADD_TITLE,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
        ),
      ),
    );
  }
}
