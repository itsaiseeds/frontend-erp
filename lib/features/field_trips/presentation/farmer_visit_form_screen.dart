import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/crop_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/field_trips_repository.dart';
import '../data/models/farmer_visit.dart';
import '../data/models/field_trip.dart';

/// Records a farmer met on a trip that is under way.
///
/// Only reachable while the trip is IN_PROGRESS, which the detail screen
/// enforces: the endpoint refuses anything else.
class FarmerVisitFormScreen extends StatefulWidget {
  final FieldTrip trip;

  /// The visit being changed, or null when recording a new one.
  final FarmerVisit? existing;

  const FarmerVisitFormScreen({
    super.key,
    required this.trip,
    this.existing,
  });

  static Future<bool?> push(
    BuildContext context, {
    required FieldTrip trip,
    FarmerVisit? existing,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FarmerVisitFormScreen(trip: trip, existing: existing),
      ),
    );
  }

  @override
  State<FarmerVisitFormScreen> createState() => _FarmerVisitFormScreenState();
}

class _FarmerVisitFormScreenState extends State<FarmerVisitFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _landController = TextEditingController();

  final List<CropModel> _crops = [];
  final List<FarmerProduct> _products = [];

  List<CropModel> _availableCrops = const [];
  List<FarmerProduct> _availableProducts = const [];

  String? _nameError;
  String? _contactError;
  String? _landError;
  String? _cropsError;

  bool _isLoading = true;
  bool _isSaving = false;

  late final FieldTripsRepository _repository = FieldTripsRepository(
    apiClient: context.read<ApiClient>(),
  );

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _seed();
    _loadLookups();
  }

  void _seed() {
    final FarmerVisit? visit = widget.existing;
    if (visit == null) {
      _villageController.text = widget.trip.village;
      return;
    }

    _nameController.text = visit.farmerName;
    _contactController.text = visit.contactNumber;
    _villageController.text = visit.village;
    _landController.text = _trimZeros(visit.landAreaBigha);
  }

  /// A land area comes back as 20.0000; the field should offer back what
  /// the user typed, not the database's padding.
  static String _trimZeros(num value) {
    final String text = value.toString();
    if (!text.contains('.')) return text;
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _villageController.dispose();
    _landController.dispose();
    super.dispose();
  }

  void _seedSelections() {
    final FarmerVisit? visit = widget.existing;
    if (visit == null) return;

    _crops
      ..clear()
      ..addAll([
        for (final CropModel crop in _availableCrops)
          if (visit.crops.any((picked) => picked.id == crop.id)) crop,
      ]);
    _products
      ..clear()
      ..addAll([
        for (final FarmerProduct product in _availableProducts)
          if (visit.products.any(
            (picked) => picked.publicId == product.publicId,
          ))
            product,
      ]);
  }

  Future<void> _loadLookups() async {
    try {
      final List<CropModel> crops = await _repository.fetchCrops();
      final List<FarmerProduct> products = await _repository.fetchProducts();
      if (!mounted) return;

      setState(() {
        _availableCrops = crops;
        _availableProducts = products;
        _isLoading = false;
        // The visit names its crops and products; the pickers work in the
        // catalogue's own objects, so they are matched once both are here.
        _seedSelections();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ToastUtils.showError(context, error.message);
    }
  }

  List<CropModel> get _remainingCrops => [
    for (final CropModel crop in _availableCrops)
      if (!_crops.any((picked) => picked.id == crop.id)) crop,
  ];

  List<FarmerProduct> get _remainingProducts => [
    for (final FarmerProduct product in _availableProducts)
      if (!_products.any((picked) => picked.publicId == product.publicId))
        product,
  ];

  /// At least one crop is required by the server, and a negative area is
  /// refused, so both are caught here rather than as a 400.
  bool _validate() {
    final String name = _nameController.text.trim();
    final String land = _landController.text.trim();
    final double? area = double.tryParse(land);

    setState(() {
      _nameError = name.isEmpty
          ? AppStrings.FARMER_VISIT_VALIDATION_NAME
          : null;
      _contactError = AppValidators.phoneNumber(_contactController.text);
      _landError = land.isEmpty || area == null
          ? AppStrings.FARMER_VISIT_VALIDATION_LAND_AREA
          : (area < 0
                ? AppStrings.FARMER_VISIT_VALIDATION_LAND_AREA_NEGATIVE
                : null);
      _cropsError = _crops.isEmpty
          ? AppStrings.FARMER_VISIT_VALIDATION_CROPS
          : null;
    });

    return _nameError == null &&
        _contactError == null &&
        _landError == null &&
        _cropsError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _submitEdit(widget.existing!);
      } else {
        await _repository.createFarmerVisit(
          fieldTripPublicId: widget.trip.publicId,
          farmerName: _nameController.text,
          contactNumber: _contactController.text,
          village: _villageController.text,
          landAreaBigha: _landController.text.trim(),
          cropIds: [for (final CropModel crop in _crops) crop.id],
          productPublicIds: [
            for (final FarmerProduct product in _products) product.publicId,
          ],
        );
      }

      if (!mounted) return;
      ToastUtils.showSuccess(
        context,
        _isEditing
            ? AppStrings.FARMER_VISIT_UPDATED
            : AppStrings.FARMER_VISIT_SAVED,
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      // The server refuses a contact number already on this trip -- it
      // guards against a resubmit on a weak signal, which is the common
      // case out in a village, so it is named rather than shown raw.
      final bool isDuplicate = error.message.toLowerCase().contains('already');
      ToastUtils.showError(
        context,
        isDuplicate ? AppStrings.FARMER_VISIT_DUPLICATE : error.message,
      );
    }
  }

  /// Sends only what moved. The land area is compared numerically so
  /// retyping 20 over 20.0000 is not treated as a change.
  Future<void> _submitEdit(FarmerVisit visit) {
    final List<int> cropIds = [for (final CropModel crop in _crops) crop.id];
    final List<String> productIds = [
      for (final FarmerProduct product in _products) product.publicId,
    ];

    final bool cropsChanged =
        cropIds.toSet() != {for (final FarmerCrop c in visit.crops) c.id};
    final bool productsChanged =
        productIds.toSet() !=
        {for (final FarmerProduct p in visit.products) p.publicId};

    final String land = _landController.text.trim();
    final bool landChanged =
        (double.tryParse(land) ?? -1) != visit.landAreaBigha.toDouble();

    return _repository.editFarmerVisit(
      publicId: visit.publicId,
      farmerName: _nameController.text.trim() == visit.farmerName
          ? null
          : _nameController.text,
      contactNumber: _contactController.text.trim() == visit.contactNumber
          ? null
          : _contactController.text,
      village: _villageController.text.trim() == visit.village
          ? null
          : _villageController.text,
      landAreaBigha: landChanged ? land : null,
      cropIds: cropsChanged ? cropIds : null,
      productPublicIds: productsChanged ? productIds : null,
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
          titleSpacing: 0,
        leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
          leading: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: AppSizes.ICON_XL,
              color: AppColors.TEXT_PRIMARY,
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          title: Text(
            _isEditing
                ? AppStrings.FARMER_VISIT_EDIT_TITLE
                : AppStrings.FARMER_VISIT_TITLE,
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
                  Text(
                    AppStrings.FARMER_VISIT_SUBTITLE,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _nameController,
                    label: AppStrings.FARMER_VISIT_NAME,
                    hint: AppStrings.FARMER_VISIT_NAME_HINT,
                    errorText: _nameError,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _contactController,
                    label: AppStrings.FARMER_VISIT_CONTACT,
                    hint: AppStrings.LOGIN_PHONE_HINT,
                    errorText: _contactError,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    prefixText: AppStrings.PHONE_COUNTRY_CODE_IN,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        AppValidators.PHONE_LENGTH,
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_contactError != null) {
                        setState(() => _contactError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _villageController,
                    label: AppStrings.FARMER_VISIT_VILLAGE,
                    hint: AppStrings.FARMER_VISIT_VILLAGE_HINT,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _landController,
                    label: AppStrings.FARMER_VISIT_LAND_AREA,
                    hint: AppStrings.FARMER_VISIT_LAND_AREA_HINT,
                    errorText: _landError,
                    isRequired: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,4}'),
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_landError != null) setState(() => _landError = null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.LG24),
                  GeoPickerField<CropModel>(
                    key: ValueKey<int>(_crops.length),
                    label: AppStrings.FARMER_VISIT_CROPS,
                    hint: AppStrings.FARMER_VISIT_PICK_CROP,
                    value: null,
                    items: _remainingCrops,
                    itemLabel: (crop) => crop.name,
                    isSame: (a, b) => a.id == b.id,
                    isRequired: true,
                    errorText: _cropsError,
                    onSelected: (crop) => setState(() {
                      _crops.add(crop);
                      _cropsError = null;
                    }),
                  ),
                  if (_crops.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.SM8),
                    _PickedChips(
                      chips: [
                        for (final CropModel crop in _crops)
                          _PickedChip(
                            label: crop.name,
                            onRemove: () => setState(() => _crops.remove(crop)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.MD16),
                  GeoPickerField<FarmerProduct>(
                    key: ValueKey<String>('p${_products.length}'),
                    label: AppStrings.FARMER_VISIT_PRODUCTS,
                    hint: AppStrings.FARMER_VISIT_PICK_PRODUCT,
                    value: null,
                    items: _remainingProducts,
                    itemLabel: (product) => product.name,
                    isSame: (a, b) => a.publicId == b.publicId,
                    onSelected: (product) =>
                        setState(() => _products.add(product)),
                  ),
                  if (_products.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.SM8),
                    _PickedChips(
                      chips: [
                        for (final FarmerProduct product in _products)
                          _PickedChip(
                            label: product.name,
                            onRemove: () =>
                                setState(() => _products.remove(product)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.XL32),
                  _SaveButton(
                    label: _isEditing
                        ? AppStrings.FIELD_TRIP_SAVE
                        : AppStrings.FARMER_VISIT_SAVE,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
      ),
    );
  }
}

/// The chips for what has been picked, under the field that picks them.
class _PickedChips extends StatelessWidget {
  final List<Widget> chips;

  const _PickedChips({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.SM8,
      runSpacing: AppSpacing.SM8,
      children: chips,
    );
  }
}

class _PickedChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _PickedChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppSpacing.SMD12,
        right: AppSpacing.SM8,
        top: AppSpacing.XS6,
        bottom: AppSpacing.XS6,
      ),
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.FULL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.PRIMARY),
          ),
          const SizedBox(width: AppSpacing.XS4),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.close_rounded,
              size: AppSizes.ICON_SM,
              color: AppColors.PRIMARY,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

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
                  label,
                  style: AppTypography.button.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
        ),
      ),
    );
  }
}
