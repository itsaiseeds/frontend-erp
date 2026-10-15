import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../data/models/raw_material_waste.dart';
import 'bloc/raw_material_waste_cubit.dart';
import 'bloc/raw_material_waste_state.dart';

/// One waste record: what was wasted, why, and who recorded it.
///
/// Unlike an inward lot there is no verification step to protect, so
/// quantity and reason stay editable for as long as the record exists, and
/// deleting it is always offered -- the server is the only thing that may
/// refuse (a waste order already drew on this row).
class RawMaterialWasteDetailScreen extends StatefulWidget {
  final RawMaterialWaste waste;

  const RawMaterialWasteDetailScreen({super.key, required this.waste});

  static Future<void> push(
    BuildContext context, {
    required RawMaterialWaste waste,
    required RawMaterialWasteCubit cubit,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<RawMaterialWasteCubit>.value(
          value: cubit,
          child: RawMaterialWasteDetailScreen(waste: waste),
        ),
      ),
    );
  }

  @override
  State<RawMaterialWasteDetailScreen> createState() =>
      _RawMaterialWasteDetailScreenState();
}

class _RawMaterialWasteDetailScreenState
    extends State<RawMaterialWasteDetailScreen> {
  late final TextEditingController _quantityController;
  late final TextEditingController _reasonController;

  bool _isEditing = false;
  String? _quantityError;

  RawMaterialWaste get _waste => widget.waste;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _waste.quantityKg);
    _reasonController = TextEditingController(text: _waste.reason);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _enterEdit() => setState(() => _isEditing = true);

  void _cancelEdit() {
    _quantityController.text = _waste.quantityKg;
    _reasonController.text = _waste.reason;
    setState(() {
      _isEditing = false;
      _quantityError = null;
    });
  }

  Future<void> _save() async {
    final String quantity = _quantityController.text.trim();
    final double? value = double.tryParse(quantity);

    setState(() {
      _quantityError = quantity.isEmpty || value == null
          ? AppStrings.WASTE_VALIDATION_QUANTITY
          : (value <= 0 ? AppStrings.WASTE_VALIDATION_QUANTITY_POSITIVE : null);
    });
    if (_quantityError != null) return;

    final RawMaterialWasteCubit cubit = context.read<RawMaterialWasteCubit>();
    final bool succeeded = await cubit.updateWaste(
      publicId: _waste.publicId,
      quantityKg: quantity,
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;
    if (succeeded) {
      setState(() => _isEditing = false);
      ToastUtils.showSuccess(context, AppStrings.WASTE_UPDATED);
      return;
    }
    ToastUtils.showServerError(
      context,
      cubit.state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
    );
  }

  Future<void> _confirmDelete() async {
    final RawMaterialWasteCubit cubit = context.read<RawMaterialWasteCubit>();

    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.WASTE_DELETE_TITLE,
      body: AppStrings.WASTE_DELETE_BODY,
      confirmLabel: AppStrings.DELETE,
      confirmColor: AppColors.ERROR,
    );
    if (!confirmed || !mounted) return;

    final bool succeeded = await cubit.deleteWaste(_waste.publicId);
    if (!mounted) return;

    if (succeeded) {
      ToastUtils.showSuccess(context, AppStrings.WASTE_DELETED);
      Navigator.of(context).pop();
      return;
    }
    ToastUtils.showServerError(
      context,
      cubit.state.errorMessage ?? AppStrings.SOMETHING_WENT_WRONG,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RawMaterialWasteCubit, RawMaterialWasteState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.BACKGROUND,
          appBar: AppBar(
            backgroundColor: AppColors.SURFACE,
            surfaceTintColor: AppColors.TRANSPARENT,
            elevation: 0,
            titleSpacing: 0,
            leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: AppSizes.ICON_XL,
                color: AppColors.TEXT_PRIMARY,
              ),
            ),
            title: Text(
              _isEditing ? AppStrings.WASTE_EDIT_TITLE : AppStrings.WASTE_DETAIL_TITLE,
              style: AppTypography.titleMedium,
            ),
            actions: _isEditing
                ? [
                    TextButton(
                      onPressed: state.isMutating ? null : _cancelEdit,
                      child: Text(
                        AppStrings.CANCEL,
                        style: AppTypography.button.copyWith(
                          color: AppColors.TEXT_SECONDARY,
                        ),
                      ),
                    ),
                  ]
                : [
                    IconButton(
                      tooltip: AppStrings.EDIT,
                      onPressed: state.isMutating ? null : _enterEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: AppSizes.ICON_LG,
                        color: AppColors.TEXT_SECONDARY,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.DELETE,
                      onPressed: state.isMutating ? null : _confirmDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: AppSizes.ICON_LG,
                        color: AppColors.ERROR,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.XS4),
                  ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.MD16,
              AppSpacing.MD16,
              AppSpacing.MD16,
              AppSizes.ORDER_LIST_BOTTOM_INSET,
            ),
            children: [
              AppTextField(
                controller: TextEditingController(text: _waste.product.name),
                label: AppStrings.WASTE_FIELD_PRODUCT,
                enabled: false,
              ),
              if (_waste.isFromRejectedLot) ...[
                const SizedBox(height: AppSpacing.MD16),
                AppTextField(
                  controller: TextEditingController(
                    text: _waste.inwardRawMaterial!.lotNo,
                  ),
                  label: AppStrings.WASTE_FROM_REJECTED_LOT_FIELD,
                  enabled: false,
                ),
              ],
              const SizedBox(height: AppSpacing.MD16),
              AppTextField(
                controller: _quantityController,
                label: AppStrings.WASTE_FIELD_QUANTITY_KG,
                enabled: _isEditing && !state.isMutating,
                errorText: _quantityError,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                ],
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
                enabled: _isEditing && !state.isMutating,
                inputFormatters: [LengthLimitingTextInputFormatter(255)],
              ),
              const SizedBox(height: AppSpacing.MD16),
              AppTextField(
                controller: TextEditingController(
                  text: DateFormatter.dayTime(_waste.createdAt),
                ),
                label: AppStrings.WASTE_FIELD_CREATED_AT,
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.MD16),
              AppTextField(
                controller: TextEditingController(
                  text: _waste.createdBy?.name ?? '',
                ),
                label: AppStrings.WASTE_FIELD_CREATED_BY,
                enabled: false,
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.XL32),
                _SaveButton(isLoading: state.isMutating, onPressed: _save),
              ],
            ],
          ),
        );
      },
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
                  AppStrings.SAVE,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
        ),
      ),
    );
  }
}
