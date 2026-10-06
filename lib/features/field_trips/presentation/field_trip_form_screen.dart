import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/city_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/metadata_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../data/field_trips_repository.dart';
import '../data/models/field_trip.dart';
import 'widgets/field_trip_picker_field.dart';
import 'widgets/trip_date_time_picker.dart';

/// Plans a new trip, or edits one that has not started.
///
/// The same form serves both: editing only differs in what it is seeded
/// with and which endpoint it calls, so a second screen would be the same
/// validation written twice.
class FieldTripFormScreen extends StatefulWidget {
  final FieldTrip? existing;

  const FieldTripFormScreen({super.key, this.existing});

  static Future<bool?> push(BuildContext context, {FieldTrip? existing}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FieldTripFormScreen(existing: existing),
      ),
    );
  }

  @override
  State<FieldTripFormScreen> createState() => _FieldTripFormScreenState();
}

class _FieldTripFormScreenState extends State<FieldTripFormScreen> {
  final TextEditingController _villageController = TextEditingController();

  CityModel? _city;
  DateTime? _startAt;
  DateTime? _endAt;

  String? _cityError;
  String? _villageError;
  String? _startError;
  String? _endError;

  bool _isSaving = false;
  bool _isLoadingCities = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _seedFromExisting();
    _loadCities();
  }

  @override
  void dispose() {
    _villageController.dispose();
    super.dispose();
  }

  void _seedFromExisting() {
    final FieldTrip? trip = widget.existing;
    if (trip == null) return;

    _villageController.text = trip.village;
    _startAt = trip.expectedStartAt;
    _endAt = trip.expectedEndAt;
  }

  /// Cities come from the cached metadata, so the picker opens instantly
  /// on every trip after the first.
  Future<void> _loadCities() async {
    await MetadataService.instance.ensureLoaded();
    if (!mounted) return;

    setState(() {
      _isLoadingCities = false;
      final int? cityId = widget.existing?.city.id;
      if (cityId != null && cityId > 0) {
        _city = MetadataService.instance.cityById(cityId);
      }
    });
  }

  Future<void> _pickStart() async {
    final DateTime? picked = await TripDateTimePicker.show(
      context,
      title: AppStrings.FIELD_TRIP_EXPECTED_START,
      initial: _startAt,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _startAt = picked;
      _startError = null;
      _endError = null;
    });
  }

  Future<void> _pickEnd() async {
    // The end cannot precede the start, so the calendar will not offer it.
    final DateTime? picked = await TripDateTimePicker.show(
      context,
      title: AppStrings.FIELD_TRIP_EXPECTED_END,
      initial: _endAt ?? _startAt,
      firstAllowed: _startAt,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _endAt = picked;
      _endError = null;
    });
  }

  /// The database rejects an end that is not strictly after the start, so
  /// the form says so rather than letting the save fail.
  bool _validate() {
    final String village = _villageController.text.trim();
    final DateTime? start = _startAt;
    final DateTime? end = _endAt;

    setState(() {
      _cityError = _city == null ? AppStrings.FIELD_TRIP_VALIDATION_CITY : null;
      _villageError = village.isEmpty
          ? AppStrings.FIELD_TRIP_VALIDATION_VILLAGE
          : null;
      _startError = start == null
          ? AppStrings.FIELD_TRIP_VALIDATION_START
          : null;
      _endError = end == null
          ? AppStrings.FIELD_TRIP_VALIDATION_END
          : (start != null && !end.isAfter(start)
                ? AppStrings.FIELD_TRIP_VALIDATION_ORDER
                : null);
    });

    return _cityError == null &&
        _villageError == null &&
        _startError == null &&
        _endError == null;
  }

  Future<void> _save() async {
    if (_isSaving || !_validate()) return;

    setState(() => _isSaving = true);

    final FieldTripsRepository repository = FieldTripsRepository(
      apiClient: context.read<ApiClient>(),
    );

    try {
      if (_isEditing) {
        await repository.editFieldTrip(
          publicId: widget.existing!.publicId,
          cityId: _city!.id,
          village: _villageController.text,
          expectedStartAt: _startAt!,
          expectedEndAt: _endAt!,
        );
      } else {
        await repository.createFieldTrip(
          cityId: _city!.id,
          village: _villageController.text,
          expectedStartAt: _startAt!,
          expectedEndAt: _endAt!,
        );
      }

      if (!mounted) return;
      ToastUtils.showSuccess(
        context,
        _isEditing
            ? AppStrings.FIELD_TRIP_UPDATED
            : AppStrings.FIELD_TRIP_CREATED,
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ToastUtils.showError(context, error.message);
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
                ? AppStrings.FIELD_TRIP_EDIT_TITLE
                : AppStrings.FIELD_TRIP_PLAN_TITLE,
            style: AppTypography.titleMedium,
          ),
        ),
        body: _isLoadingCities
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.PRIMARY),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.MD16),
                children: [
                  Text(
                    AppStrings.FIELD_TRIP_PLAN_SUBTITLE,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_SECONDARY,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  GeoPickerField<CityModel>(
                    label: AppStrings.FIELD_TRIP_CITY,
                    hint: AppStrings.FIELD_TRIP_PICK_CITY,
                    value: _city,
                    items: MetadataService.instance.cities,
                    itemLabel: (city) => city.name,
                    isSame: (a, b) => a.id == b.id,
                    isRequired: true,
                    errorText: _cityError,
                    onSelected: (city) => setState(() {
                      _city = city;
                      _cityError = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _villageController,
                    label: AppStrings.FIELD_TRIP_VILLAGE,
                    hint: AppStrings.FIELD_TRIP_VILLAGE_HINT,
                    errorText: _villageError,
                    isRequired: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_villageError != null) {
                        setState(() => _villageError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.LG24),
                  Text(
                    AppStrings.FIELD_TRIP_WINDOW,
                    style: AppTypography.labelStrong,
                  ),
                  const SizedBox(height: AppSpacing.SMD12),
                  FieldTripPickerField(
                    label: AppStrings.FIELD_TRIP_EXPECTED_START,
                    hint: AppStrings.FIELD_TRIP_PICK_START,
                    value: _startAt == null
                        ? null
                        : DateFormatter.dayTime(_startAt),
                    icon: Icons.play_circle_outline_rounded,
                    errorText: _startError,
                    isRequired: true,
                    onTap: _pickStart,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  FieldTripPickerField(
                    label: AppStrings.FIELD_TRIP_EXPECTED_END,
                    hint: AppStrings.FIELD_TRIP_PICK_END,
                    value: _endAt == null
                        ? null
                        : DateFormatter.dayTime(_endAt),
                    icon: Icons.stop_circle_outlined,
                    errorText: _endError,
                    isRequired: true,
                    onTap: _pickEnd,
                  ),
                  const SizedBox(height: AppSpacing.XL32),
                  _SaveButton(
                    label: _isEditing
                        ? AppStrings.FIELD_TRIP_SAVE
                        : AppStrings.FIELD_TRIP_CREATE,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
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
