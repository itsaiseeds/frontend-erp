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
import '../data/models/other_material_recipe.dart';
import 'bloc/inward_other_cubit.dart';

class InwardOtherFormScreen extends StatefulWidget {
  const InwardOtherFormScreen({super.key});

  static Future<bool?> push(
    BuildContext context, {
    required InwardOtherCubit cubit,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider<InwardOtherCubit>.value(
          value: cubit,
          child: const InwardOtherFormScreen(),
        ),
      ),
    );
  }

  @override
  State<InwardOtherFormScreen> createState() => _InwardOtherFormScreenState();
}

class _InwardOtherFormScreenState extends State<InwardOtherFormScreen> {
  final TextEditingController _quantityController = TextEditingController();

  GodownPickableParty? _party;
  OtherMaterialRecipe? _recipe;

  List<GodownPickableParty> _parties = const [];
  List<OtherMaterialRecipe> _recipes = const [];

  String? _partyError;
  String? _recipeError;
  String? _quantityError;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final GodownRepository repository = GodownRepository(
      apiClient: context.read<ApiClient>(),
    );
    try {
      final List<GodownPickableParty> parties = await repository.fetchParties(
        partyType: GodownPartyType.otherMaterial,
      );
      final List<OtherMaterialRecipe> recipes = await repository
          .fetchOtherMaterialRecipes();
      if (!mounted) return;
      setState(() {
        _parties = parties;
        _recipes = recipes;
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
      _partyError = _party == null ? AppStrings.INWARD_VALIDATION_PARTY : null;
      _recipeError = _recipe == null
          ? AppStrings.INWARD_VALIDATION_RECIPE
          : null;
      _quantityError = quantity.isEmpty || value == null
          ? AppStrings.INWARD_VALIDATION_QUANTITY
          : (value <= 0
                ? AppStrings.INWARD_VALIDATION_QUANTITY_POSITIVE
                : null);
    });

    return _partyError == null &&
        _recipeError == null &&
        _quantityError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;
    setState(() => _isSaving = true);

    final bool succeeded = await context.read<InwardOtherCubit>().bookLot(
      partyId: _party!.id,
      recipePublicId: _recipe!.publicId,
      quantity: _quantityController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (succeeded) {
      ToastUtils.showSuccess(context, AppStrings.INWARD_BOOKED_OTHER);
      Navigator.of(context).pop(true);
      return;
    }
    ToastUtils.showServerError(
      context,
      context.read<InwardOtherCubit>().state.errorMessage ??
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
            AppStrings.INWARD_BOOK_OTHER,
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
                  GeoPickerField<OtherMaterialRecipe>(
                    label: AppStrings.INWARD_FIELD_RECIPE,
                    hint: AppStrings.INWARD_FIELD_RECIPE_HINT,
                    value: _recipe,
                    items: _recipes,
                    itemLabel: (recipe) => recipe.label,
                    isSame: (a, b) => a.publicId == b.publicId,
                    isRequired: true,
                    errorText: _recipeError,
                    onSelected: (recipe) => setState(() {
                      _recipe = recipe;
                      _recipeError = null;
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
                    controller: _quantityController,
                    label: AppStrings.INWARD_FIELD_QUANTITY,
                    hint: AppStrings.INWARD_FIELD_QUANTITY_HINT,
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
                  AppStrings.INWARD_BOOK_OTHER,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
        ),
      ),
    );
  }
}
