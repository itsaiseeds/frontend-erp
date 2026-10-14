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

/// Moves raw-material stock from one product to another of the same crop --
/// two products can share the same underlying seed (e.g. SAI-33 and
/// SAI-Balwan), and this lets the godown manager correct which product that
/// in-use stock is currently sitting under. Kilograms only; the server is
/// the one that actually enforces "same crop" and "different products", this
/// screen's own checks are just a head start so a bad pick never reaches it.
class ProductStockTransferScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const ProductStockTransferScreen({super.key, required this.onMenuTap});

  @override
  State<ProductStockTransferScreen> createState() =>
      _ProductStockTransferScreenState();
}

class _ProductStockTransferScreenState
    extends State<ProductStockTransferScreen> {
  final TextEditingController _quantityController = TextEditingController();

  GodownPickableProduct? _source;
  GodownPickableProduct? _target;
  List<GodownPickableProduct> _products = const [];

  String? _sourceError;
  String? _targetError;
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

  /// Target products limited to the source's own crop -- same intent as the
  /// server's own rule, just applied before the picker ever opens.
  List<GodownPickableProduct> get _targetOptions {
    final GodownPickableProduct? source = _source;
    if (source == null) return const [];
    return _products
        .where(
          (product) =>
              product.publicId != source.publicId &&
              product.cropId == source.cropId,
        )
        .toList();
  }

  void _selectSource(GodownPickableProduct product) {
    setState(() {
      _source = product;
      _sourceError = null;
      // A target from a different crop (or the new source itself) can no
      // longer be valid, so it is cleared rather than silently kept.
      if (_target != null &&
          (_target!.publicId == product.publicId ||
              _target!.cropId != product.cropId)) {
        _target = null;
      }
    });
  }

  bool _validate() {
    final String quantity = _quantityController.text.trim();
    final double? value = double.tryParse(quantity);

    setState(() {
      _sourceError = _source == null
          ? AppStrings.TRANSFER_VALIDATION_SOURCE
          : null;
      _targetError = _target == null
          ? AppStrings.TRANSFER_VALIDATION_TARGET
          : (_source != null && _target!.publicId == _source!.publicId
                ? AppStrings.TRANSFER_VALIDATION_SAME_PRODUCT
                : null);
      _quantityError = quantity.isEmpty || value == null
          ? AppStrings.TRANSFER_VALIDATION_QUANTITY
          : (value <= 0
                ? AppStrings.TRANSFER_VALIDATION_QUANTITY_POSITIVE
                : null);
    });

    return _sourceError == null &&
        _targetError == null &&
        _quantityError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;
    setState(() => _isSaving = true);

    final GodownRepository repository = GodownRepository(
      apiClient: context.read<ApiClient>(),
    );

    try {
      await repository.transferProductStock(
        sourceProductPublicId: _source!.publicId,
        targetProductPublicId: _target!.publicId,
        quantityKg: _quantityController.text.trim(),
      );
      if (!mounted) return;
      ToastUtils.showSuccess(context, AppStrings.TRANSFER_DONE);
      setState(() {
        _source = null;
        _target = null;
        _isSaving = false;
      });
      _quantityController.clear();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ToastUtils.showServerError(context, error.message);
    }
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
            onPressed: widget.onMenuTap,
            icon: const Icon(
              Icons.menu_rounded,
              size: AppSizes.HOME_APP_BAR_ICON,
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
          title: Text(AppStrings.TRANSFER_TITLE, style: AppTypography.titleMedium),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.PRIMARY),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.MD16),
                children: [
                  Text(
                    AppStrings.TRANSFER_SUBTITLE,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  GeoPickerField<GodownPickableProduct>(
                    label: AppStrings.TRANSFER_FIELD_SOURCE,
                    hint: AppStrings.TRANSFER_FIELD_SOURCE_HINT,
                    value: _source,
                    items: _products,
                    itemLabel: (product) => product.name,
                    isSame: (a, b) => a.publicId == b.publicId,
                    isRequired: true,
                    errorText: _sourceError,
                    onSelected: _selectSource,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  GeoPickerField<GodownPickableProduct>(
                    label: AppStrings.TRANSFER_FIELD_TARGET,
                    hint: AppStrings.TRANSFER_FIELD_TARGET_HINT,
                    value: _target,
                    items: _targetOptions,
                    itemLabel: (product) => product.name,
                    isSame: (a, b) => a.publicId == b.publicId,
                    isRequired: true,
                    enabled: _source != null,
                    errorText: _targetError,
                    disabledHint: _source == null
                        ? AppStrings.TRANSFER_FIELD_TARGET_PICK_SOURCE_FIRST
                        : AppStrings.TRANSFER_FIELD_TARGET_NONE_IN_CROP,
                    onSelected: (product) => setState(() {
                      _target = product;
                      _targetError = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _quantityController,
                    label: AppStrings.TRANSFER_FIELD_QUANTITY_KG,
                    hint: AppStrings.TRANSFER_FIELD_QUANTITY_KG_HINT,
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
                  const SizedBox(height: AppSpacing.XL32),
                  _TransferButton(isLoading: _isSaving, onPressed: _save),
                ],
              ),
      ),
    );
  }
}

class _TransferButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _TransferButton({required this.isLoading, required this.onPressed});

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
                  AppStrings.TRANSFER_ACTION,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
        ),
      ),
    );
  }
}
