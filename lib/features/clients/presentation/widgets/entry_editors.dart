import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_defaults.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/city_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/models/country_model.dart';
import '../../../../core/models/state_model.dart';
import '../../../../core/services/metadata_service.dart';
import '../../../../core/widgets/inputs/geo_picker_field.dart';
import '../../../../core/widgets/inputs/main_flag_toggle.dart';
import '../../../../core/widgets/feedback/field_group_label.dart';
import '../../../../core/widgets/layout/form_screen_scaffold.dart';
import '../bloc/client_form_state.dart';

class _MainConflictNotice extends StatelessWidget {
  const _MainConflictNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.SMD12),
      decoration: BoxDecoration(
        color: AppColors.WARNING_LIGHT,
        border: Border.all(color: AppColors.WARNING_BORDER),
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: AppSizes.ICON_MD,
            color: AppColors.WARNING,
          ),
          const SizedBox(width: AppSpacing.SM8),
          Expanded(
            child: Text(
              AppStrings.CLIENT_MAIN_CONFLICT,
              style: AppTypography.caption.copyWith(
                color: AppColors.WARNING,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddressEditor extends StatefulWidget {
  final AddressDraft? initial;
  final bool isFirstEntry;
  final bool hasOtherMain;

  const AddressEditor({
    super.key,
    this.initial,
    this.isFirstEntry = false,
    this.hasOtherMain = false,
  });

  static Future<AddressDraft?> show(
    BuildContext context, {
    AddressDraft? initial,
    bool isFirstEntry = false,
    bool hasOtherMain = false,
  }) {
    return Navigator.of(context).push<AddressDraft>(
      MaterialPageRoute<AddressDraft>(
        builder: (_) => AddressEditor(
          initial: initial,
          isFirstEntry: isFirstEntry,
          hasOtherMain: hasOtherMain,
        ),
      ),
    );
  }

  @override
  State<AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<AddressEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _pincodeController;

  CountryModel? _country;
  StateModel? _state;
  CityModel? _city;
  String? _cityError;
  String? _stateError;
  bool _isMain = false;
  bool _autovalidate = false;
  bool _isDirty = false;

  void _markDirty() {
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    final AddressDraft? initial = widget.initial;
    _labelController = TextEditingController(text: initial?.label ?? '');
    _line1Controller = TextEditingController(text: initial?.line1 ?? '');
    _line2Controller = TextEditingController(text: initial?.line2 ?? '');
    _pincodeController = TextEditingController(text: initial?.pincode ?? '');
    _city = initial?.city;
    _state = MetadataService.instance.stateById(initial?.city?.stateId);
    _country = _resolveInitialCountry(initial);
    _isMain = initial?.isMain ?? widget.isFirstEntry;
  }

  static CountryModel? _resolveInitialCountry(AddressDraft? initial) {
    final MetadataService meta = MetadataService.instance;
    final StateModel? state = meta.stateById(initial?.city?.stateId);
    if (state != null && state.countryId != 0) {
      return meta.countryById(state.countryId);
    }
    final List<CountryModel> countries = meta.countries;
    if (countries.length == 1) return countries.first;
    return meta.countryById(AppDefaults.COUNTRY_ID);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void submit() {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    final String? cityError = _city == null
        ? AppStrings.CLIENT_VALIDATION_CITY
        : null;
    final String? stateError = _state == null
        ? AppStrings.CLIENT_VALIDATION_STATE
        : null;

    setState(() {
      _autovalidate = true;
      _cityError = cityError;
      _stateError = stateError;
    });
    if (!isValid || cityError != null || stateError != null) return;

    Navigator.of(context).pop(
      AddressDraft(
        key: widget.initial?.key ?? 0,
        label: _labelController.text.trim(),
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim(),
        city: _city,
        state: _state,
        country: _country,
        pincode: _pincodeController.text.trim(),
        isMain: _isMain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showConflict =
        _isMain && widget.hasOtherMain && !(widget.initial?.isMain ?? false);

    return FormScreenScaffold(
      title: widget.initial == null
          ? AppStrings.CLIENT_ADD_ADDRESS
          : AppStrings.CLIENT_EDIT_ADDRESS,
      actionLabel: widget.initial == null
          ? AppStrings.ADD
          : AppStrings.SAVE_CHANGES,
      onAction: submit,
      hasUnsavedChanges: _isDirty,
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        onChanged: _markDirty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const FieldGroupLabel(label: AppStrings.CLIENT_GROUP_LOCATION),
            const SizedBox(height: AppSpacing.SMD12),
            AppTextField(
              controller: _line1Controller,
              label: AppStrings.CLIENT_FIELD_LINE1,
              labelStyle: AppTypography.labelStrong,
              hint: AppStrings.CLIENT_FIELD_LINE1_HINT,
              isRequired: true,
              autofocus: widget.initial == null,
              textInputAction: TextInputAction.next,
              validator: (value) => AppValidators.requiredField(
                value,
                AppStrings.CLIENT_VALIDATION_LINE1,
              ),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            AppTextField(
              controller: _line2Controller,
              label: AppStrings.CLIENT_FIELD_LINE2,
              labelStyle: AppTypography.labelStrong,
              hint: AppStrings.CLIENT_FIELD_LINE2_HINT,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.SMD12),
            GeoPickerField<CountryModel>(
              label: AppStrings.CLIENT_FIELD_COUNTRY,
              hint: AppStrings.CLIENT_FIELD_COUNTRY_HINT,
              value: _country,
              items: MetadataService.instance.countries,
              itemLabel: (country) => country.name,
              isSame: (a, b) => a.id == b.id,
              isRequired: true,
              onSelected: (country) => setState(() {
                _isDirty = true;
                if (_country?.id != country.id) {
                  _state = null;
                  _city = null;
                }
                _country = country;
              }),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            GeoPickerField<StateModel>(
              label: AppStrings.CLIENT_FIELD_STATE,
              hint: AppStrings.CLIENT_FIELD_STATE_HINT,
              value: _state,
              items: MetadataService.instance.statesInCountry(_country?.id),
              itemLabel: (state) => state.name,
              isSame: (a, b) => a.id == b.id,
              isRequired: true,
              enabled: _country != null,
              disabledHint: AppStrings.CLIENT_FIELD_STATE_LOCKED,
              errorText: _stateError,
              onSelected: (state) => setState(() {
                _isDirty = true;
                if (_state?.id != state.id) _city = null;
                _state = state;
                _stateError = null;
              }),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            GeoPickerField<CityModel>(
              label: AppStrings.CLIENT_FIELD_CITY,
              hint: AppStrings.CLIENT_FIELD_CITY_HINT,
              value: _city,
              items: MetadataService.instance.citiesInState(_state?.id),
              itemLabel: (city) => city.name,
              isSame: (a, b) => a.id == b.id,
              isRequired: true,
              enabled: _state != null,
              disabledHint: AppStrings.CLIENT_FIELD_CITY_LOCKED,
              errorText: _cityError,
              onSelected: (city) => setState(() {
                _isDirty = true;
                _city = city;
                _cityError = null;
              }),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            AppTextField(
              controller: _pincodeController,
              label: AppStrings.CLIENT_FIELD_PINCODE,
              labelStyle: AppTypography.labelStrong,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppValidators.PINCODE_LENGTH),
              ],
              validator: AppValidators.pincode,
            ),
            const SizedBox(height: AppSpacing.MD16),
            const FieldGroupLabel(label: AppStrings.CLIENT_GROUP_LABELLING),
            const SizedBox(height: AppSpacing.SMD12),
            AppTextField(
              controller: _labelController,
              label: AppStrings.CLIENT_FIELD_LABEL,
              labelStyle: AppTypography.labelStrong,
              hint: AppStrings.CLIENT_FIELD_LABEL_HINT,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.SMD12),
            MainFlagToggle(
              value: _isMain,
              enabled: !widget.isFirstEntry,
              label: AppStrings.CLIENT_FIELD_IS_MAIN,
              hint: widget.isFirstEntry
                  ? AppStrings.CLIENT_FIELD_IS_MAIN_LOCKED
                  : AppStrings.CLIENT_FIELD_IS_MAIN_HINT,
              onChanged: (value) => setState(() {
                _isMain = value;
                _isDirty = true;
              }),
            ),
            if (showConflict) ...[
              const SizedBox(height: AppSpacing.SMD12),
              const _MainConflictNotice(),
            ],
          ],
        ),
      ),
    );
  }
}

class ContactEditor extends StatefulWidget {
  final ContactDraft? initial;
  final bool isFirstEntry;
  final bool hasOtherMain;

  const ContactEditor({
    super.key,
    this.initial,
    this.isFirstEntry = false,
    this.hasOtherMain = false,
  });

  static Future<ContactDraft?> show(
    BuildContext context, {
    ContactDraft? initial,
    bool isFirstEntry = false,
    bool hasOtherMain = false,
  }) {
    return Navigator.of(context).push<ContactDraft>(
      MaterialPageRoute<ContactDraft>(
        builder: (_) => ContactEditor(
          initial: initial,
          isFirstEntry: isFirstEntry,
          hasOtherMain: hasOtherMain,
        ),
      ),
    );
  }

  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;

  bool _isMain = false;
  bool _autovalidate = false;
  bool _isDirty = false;

  void _markDirty() {
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.initial?.phoneNumber ?? '',
    );
    _roleController = TextEditingController(text: widget.initial?.role ?? '');
    _isMain = widget.initial?.isMain ?? widget.isFirstEntry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void submit() {
    setState(() => _autovalidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      ContactDraft(
        key: widget.initial?.key ?? 0,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: _roleController.text.trim(),
        isMain: _isMain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showConflict =
        _isMain && widget.hasOtherMain && !(widget.initial?.isMain ?? false);

    return FormScreenScaffold(
      title: widget.initial == null
          ? AppStrings.CLIENT_ADD_CONTACT
          : AppStrings.CLIENT_EDIT_CONTACT,
      actionLabel: widget.initial == null
          ? AppStrings.ADD
          : AppStrings.SAVE_CHANGES,
      onAction: submit,
      hasUnsavedChanges: _isDirty,
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        onChanged: _markDirty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: AppStrings.CLIENT_FIELD_CONTACT_NAME,
              labelStyle: AppTypography.labelStrong,
              hint: AppStrings.CLIENT_FIELD_CONTACT_NAME_HINT,
              isRequired: true,
              autofocus: widget.initial == null,
              textInputAction: TextInputAction.next,
              validator: (value) => AppValidators.requiredField(
                value,
                AppStrings.CLIENT_VALIDATION_CONTACT_NAME,
              ),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            AppTextField(
              controller: _phoneController,
              label: AppStrings.CLIENT_FIELD_PHONE,
              labelStyle: AppTypography.labelStrong,
              prefixText: AppStrings.PHONE_COUNTRY_CODE_IN,
              isRequired: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppValidators.PHONE_LENGTH),
              ],
              validator: (value) => AppValidators.phoneNumber(value),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            AppTextField(
              controller: _roleController,
              label: AppStrings.CLIENT_FIELD_ROLE,
              labelStyle: AppTypography.labelStrong,
              hint: AppStrings.CLIENT_FIELD_ROLE_HINT,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.MD16),
            MainFlagToggle(
              value: _isMain,
              enabled: !widget.isFirstEntry,
              label: AppStrings.CLIENT_FIELD_IS_MAIN_CONTACT,
              hint: widget.isFirstEntry
                  ? AppStrings.CLIENT_FIELD_IS_MAIN_LOCKED
                  : AppStrings.CLIENT_FIELD_IS_MAIN_HINT,
              onChanged: (value) => setState(() {
                _isMain = value;
                _isDirty = true;
              }),
            ),
            if (showConflict) ...[
              const SizedBox(height: AppSpacing.SMD12),
              const _MainConflictNotice(),
            ],
          ],
        ),
      ),
    );
  }
}

class TransportEditor extends StatefulWidget {
  final TransportDraft? initial;
  final bool isFirstEntry;
  final bool hasOtherMain;

  const TransportEditor({
    super.key,
    this.initial,
    this.isFirstEntry = false,
    this.hasOtherMain = false,
  });

  static Future<TransportDraft?> show(
    BuildContext context, {
    TransportDraft? initial,
    bool isFirstEntry = false,
    bool hasOtherMain = false,
  }) {
    return Navigator.of(context).push<TransportDraft>(
      MaterialPageRoute<TransportDraft>(
        builder: (_) => TransportEditor(
          initial: initial,
          isFirstEntry: isFirstEntry,
          hasOtherMain: hasOtherMain,
        ),
      ),
    );
  }

  @override
  State<TransportEditor> createState() => _TransportEditorState();
}

class _TransportEditorState extends State<TransportEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _isMain = false;
  bool _autovalidate = false;
  bool _isDirty = false;

  void _markDirty() {
    if (_isDirty) return;
    setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _isMain = widget.initial?.isMain ?? widget.isFirstEntry;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void submit() {
    setState(() => _autovalidate = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      TransportDraft(
        key: widget.initial?.key ?? 0,
        name: _nameController.text.trim(),
        isMain: _isMain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showConflict =
        _isMain && widget.hasOtherMain && !(widget.initial?.isMain ?? false);

    return FormScreenScaffold(
      title: widget.initial == null
          ? AppStrings.CLIENT_ADD_TRANSPORT
          : AppStrings.CLIENT_EDIT_TRANSPORT,
      actionLabel: widget.initial == null
          ? AppStrings.ADD
          : AppStrings.SAVE_CHANGES,
      onAction: submit,
      hasUnsavedChanges: _isDirty,
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        onChanged: _markDirty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: AppStrings.CLIENT_FIELD_AGENCY_NAME,
              labelStyle: AppTypography.labelStrong,
              hint: AppStrings.CLIENT_FIELD_AGENCY_NAME_HINT,
              isRequired: true,
              autofocus: widget.initial == null,
              textInputAction: TextInputAction.done,
              validator: (value) => AppValidators.requiredField(
                value,
                AppStrings.CLIENT_VALIDATION_AGENCY_NAME,
              ),
            ),
            const SizedBox(height: AppSpacing.MD16),
            MainFlagToggle(
              value: _isMain,
              enabled: !widget.isFirstEntry,
              label: AppStrings.CLIENT_FIELD_IS_MAIN_TRANSPORT,
              hint: widget.isFirstEntry
                  ? AppStrings.CLIENT_FIELD_IS_MAIN_LOCKED
                  : AppStrings.CLIENT_FIELD_IS_MAIN_HINT,
              onChanged: (value) => setState(() {
                _isMain = value;
                _isDirty = true;
              }),
            ),
            if (showConflict) ...[
              const SizedBox(height: AppSpacing.SMD12),
              const _MainConflictNotice(),
            ],
          ],
        ),
      ),
    );
  }
}
