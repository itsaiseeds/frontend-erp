import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../../core/widgets/layout/keyboard_aware_footer.dart';
import '../data/clients_repository.dart';
import '../data/models/client.dart';
import 'bloc/client_form_cubit.dart';
import 'bloc/client_form_state.dart';
import 'widgets/entry_editors.dart';
import 'widgets/entry_tile.dart';
import 'widgets/form_step_indicator.dart';

class ClientFormScreen extends StatelessWidget {
  final Client? existing;

  const ClientFormScreen({super.key, this.existing});

  static Future<bool?> push(BuildContext context, {Client? existing}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClientFormScreen(existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClientFormCubit>(
      create: (context) => ClientFormCubit(
        repository: ClientsRepository(apiClient: context.read<ApiClient>()),
        existing: existing,
      ),
      child: _ClientFormView(isEditing: existing != null),
    );
  }
}

class _ClientFormView extends StatefulWidget {
  final bool isEditing;

  const _ClientFormView({required this.isEditing});

  @override
  State<_ClientFormView> createState() => _ClientFormViewState();
}

class _ClientFormViewState extends State<_ClientFormView> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    final ClientFormState state = context.read<ClientFormCubit>().state;
    _nameController.text = state.name;
    _phoneController.text = state.phoneNumber;
    _gstController = TextEditingController(text: state.gstNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final cubit = context.read<ClientFormCubit>();
    if (!cubit.state.hasAnyInput) return true;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.SURFACE,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.XL),
        ),
        title: Text(
          AppStrings.CLIENT_DISCARD_TITLE,
          style: AppTypography.titleMedium,
        ),
        content: Text(
          AppStrings.CLIENT_DISCARD_BODY,
          style: AppTypography.bodySmall.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              AppStrings.CANCEL,
              style: AppTypography.button.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppStrings.CLIENT_DISCARD_CONFIRM,
              style: AppTypography.button.copyWith(color: AppColors.ERROR),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _onPrimaryAction() {
    final cubit = context.read<ClientFormCubit>();
    final ClientFormState state = cubit.state;
    FocusScope.of(context).unfocus();

    switch (state.step) {
      case ClientFormStep.details:
        if (!(_detailsFormKey.currentState?.validate() ?? false)) return;
        cubit.nextStep();
      case ClientFormStep.addresses:
        if (state.addresses.isEmpty) {
          ToastUtils.showWarning(
            context,
            AppStrings.CLIENT_VALIDATION_NEED_ADDRESS,
          );
          return;
        }
        cubit.nextStep();
      case ClientFormStep.contacts:
        if (state.contacts.isEmpty) {
          ToastUtils.showWarning(
            context,
            AppStrings.CLIENT_VALIDATION_NEED_CONTACT,
          );
          return;
        }
        cubit.nextStep();
      case ClientFormStep.transport:
        cubit.submit();
    }
  }

  String _progressText(ClientFormState state) {
    final int offset = widget.isEditing ? ClientFormStep.addresses.index : 0;
    final int current = state.stepIndex - offset + 1;
    final int total = state.stepCount - offset;
    return '${AppStrings.CLIENT_STEP_PROGRESS} $current '
        '${AppStrings.CLIENT_STEP_OF} $total';
  }

  String _stepLabel(ClientFormStep step) {
    switch (step) {
      case ClientFormStep.details:
        return AppStrings.CLIENT_STEP_DETAILS;
      case ClientFormStep.addresses:
        return AppStrings.CLIENT_STEP_ADDRESSES;
      case ClientFormStep.contacts:
        return AppStrings.CLIENT_STEP_CONTACTS;
      case ClientFormStep.transport:
        return AppStrings.CLIENT_STEP_TRANSPORT;
    }
  }

  Future<void> _handleBack(ClientFormState state) async {
    final cubit = context.read<ClientFormCubit>();
    FocusScope.of(context).unfocus();

    if (!cubit.isOnFirstEditableStep) {
      cubit.previousStep();
      return;
    }
    if (await _confirmDiscard() && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientFormCubit, ClientFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ClientFormStatus.success) {
          ToastUtils.showSuccess(
            context,
            widget.isEditing
                ? AppStrings.CLIENT_UPDATED
                : AppStrings.CLIENT_SAVED,
          );
          Navigator.of(context).pop(true);
          return;
        }
        if (state.status == ClientFormStatus.failure) {
          ToastUtils.showError(
            context,
            state.errorMessage ?? AppStrings.CLIENT_SAVE_FAILED,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ClientFormCubit>();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBack(state);
          },
          child: Scaffold(
            backgroundColor: AppColors.BACKGROUND,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: AppColors.SURFACE,
              surfaceTintColor: AppColors.TRANSPARENT,
              leading: IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: AppSizes.ICON_XXL,
                  color: AppColors.TEXT_PRIMARY,
                ),
                onPressed: () => _handleBack(state),
              ),
              title: Text(
                widget.isEditing
                    ? AppStrings.CLIENT_EDIT_TITLE
                    : AppStrings.CLIENT_ADD_TITLE,
                style: AppTypography.titleMedium,
              ),
            ),
            body: DismissKeyboard(
              child: Column(
                children: [
                  Container(
                    color: AppColors.SURFACE,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.MD16,
                      0,
                      AppSpacing.MD16,
                      AppSpacing.MD16,
                    ),
                    child: FormStepIndicator(
                      stepIndex: state.stepIndex,
                      stepCount: state.stepCount,
                      label: _stepLabel(state.step),
                      progressText: _progressText(state),
                      minStepIndex: widget.isEditing
                          ? ClientFormStep.addresses.index
                          : 0,
                      onStepTapped: (index) {
                        FocusScope.of(context).unfocus();
                        cubit.goToStep(ClientFormStep.values[index]);
                      },
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.MD16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: _StepBody(
                        state: state,
                        detailsFormKey: _detailsFormKey,
                        nameController: _nameController,
                        phoneController: _phoneController,
                        gstController: _gstController,
                      ),
                    ),
                  ),
                  KeyboardAwareFooter(
                    child: Row(
                      children: [
                        if (!cubit.isOnFirstEditableStep) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : cubit.previousStep,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  AppSizes.BUTTON_MIN_WIDTH,
                                  AppSizes.BUTTON_HEIGHT,
                                ),
                                side: const BorderSide(color: AppColors.BORDER),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.MD,
                                  ),
                                ),
                              ),
                              child: Text(
                                AppStrings.BACK,
                                style: AppTypography.button.copyWith(
                                  color: AppColors.TEXT_PRIMARY,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.SMD12),
                        ],
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            label: state.isLastStep
                                ? (widget.isEditing
                                      ? AppStrings.SAVE_CHANGES
                                      : AppStrings.CLIENT_SAVE)
                                : AppStrings.NEXT,
                            isLoading: state.isSubmitting,
                            onPressed: _onPrimaryAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  final ClientFormState state;
  final GlobalKey<FormState> detailsFormKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController gstController;

  const _StepBody({
    required this.state,
    required this.detailsFormKey,
    required this.nameController,
    required this.phoneController,
    required this.gstController,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClientFormCubit>();

    switch (state.step) {
      case ClientFormStep.details:
        return Form(
          key: detailsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: nameController,
                label: AppStrings.CLIENT_FIELD_NAME,
                labelStyle: AppTypography.labelStrong,
                hint: AppStrings.CLIENT_FIELD_NAME_HINT,
                textInputAction: TextInputAction.next,
                onChanged: cubit.updateName,
                validator: (value) => AppValidators.requiredField(
                  value,
                  AppStrings.CLIENT_VALIDATION_NAME,
                ),
              ),
              const SizedBox(height: AppSpacing.MD16),
              AppTextField(
                controller: phoneController,
                label: AppStrings.CLIENT_FIELD_PHONE,
                labelStyle: AppTypography.labelStrong,
                prefixText: AppStrings.PHONE_COUNTRY_CODE_IN,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(AppValidators.PHONE_LENGTH),
                ],
                onChanged: cubit.updatePhoneNumber,
                validator: (value) => AppValidators.phoneNumber(value),
              ),
              const SizedBox(height: AppSpacing.MD16),
              AppTextField(
                controller: gstController,
                label: AppStrings.CLIENT_FIELD_GST,
                labelStyle: AppTypography.labelStrong,
                hint: AppStrings.CLIENT_FIELD_GST_HINT,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(AppValidators.GST_LENGTH),
                  UpperCaseTextFormatter(),
                ],
                onChanged: cubit.updateGstNumber,
                validator: AppValidators.gstNumber,
              ),
            ],
          ),
        );

      case ClientFormStep.addresses:
        return _EntryList(
          isEmpty: state.addresses.isEmpty,
          emptyMessage: AppStrings.CLIENT_NO_ADDRESSES_YET,
          addLabel: AppStrings.CLIENT_ADD_ADDRESS,
          onAdd: () async {
            final draft = await AddressEditor.show(
              context,
              isFirstEntry: state.addresses.isEmpty,
              hasOtherMain: state.addresses.any((a) => a.isMain),
            );
            if (draft != null) cubit.addAddress(draft);
          },
          children: state.addresses
              .map(
                (address) => EntryTile(
                  icon: Icons.location_on_outlined,
                  title: address.title,
                  subtitle: address.summary,
                  isMain: address.isMain,
                  onEdit: () async {
                    final draft = await AddressEditor.show(
                      context,
                      initial: address,
                      isFirstEntry: state.addresses.length == 1,
                      hasOtherMain: state.addresses.any(
                        (a) => a.isMain && a.key != address.key,
                      ),
                    );
                    if (draft != null) {
                      cubit.updateAddress(address.key, draft);
                    }
                  },
                  onRemove: () => cubit.removeAddress(address.key),
                ),
              )
              .toList(),
        );

      case ClientFormStep.contacts:
        return _EntryList(
          isEmpty: state.contacts.isEmpty,
          emptyMessage: AppStrings.CLIENT_NO_CONTACTS_YET,
          addLabel: AppStrings.CLIENT_ADD_CONTACT,
          onAdd: () async {
            final draft = await ContactEditor.show(
              context,
              isFirstEntry: state.contacts.isEmpty,
              hasOtherMain: state.contacts.any((c) => c.isMain),
            );
            if (draft != null) cubit.addContact(draft);
          },
          children: state.contacts
              .map(
                (contact) => EntryTile(
                  icon: Icons.person_outline_rounded,
                  title: contact.name,
                  subtitle: [
                    contact.phoneNumber,
                    contact.role,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  isMain: contact.isMain,
                  onEdit: () async {
                    final draft = await ContactEditor.show(
                      context,
                      initial: contact,
                      isFirstEntry: state.contacts.length == 1,
                      hasOtherMain: state.contacts.any(
                        (c) => c.isMain && c.key != contact.key,
                      ),
                    );
                    if (draft != null) {
                      cubit.updateContact(contact.key, draft);
                    }
                  },
                  onRemove: () => cubit.removeContact(contact.key),
                ),
              )
              .toList(),
        );

      case ClientFormStep.transport:
        return _EntryList(
          isEmpty: state.transportAgencies.isEmpty,
          emptyMessage: AppStrings.CLIENT_NO_TRANSPORT_YET,
          addLabel: AppStrings.CLIENT_ADD_TRANSPORT,
          onAdd: () async {
            final draft = await TransportEditor.show(
              context,
              isFirstEntry: state.transportAgencies.isEmpty,
              hasOtherMain: state.transportAgencies.any((t) => t.isMain),
            );
            if (draft != null) cubit.addTransportAgency(draft);
          },
          children: state.transportAgencies
              .map(
                (agency) => EntryTile(
                  icon: Icons.local_shipping_outlined,
                  title: agency.name,
                  subtitle: '',
                  isMain: agency.isMain,
                  onEdit: () async {
                    final draft = await TransportEditor.show(
                      context,
                      initial: agency,
                      isFirstEntry: state.transportAgencies.length == 1,
                      hasOtherMain: state.transportAgencies.any(
                        (t) => t.isMain && t.key != agency.key,
                      ),
                    );
                    if (draft != null) {
                      cubit.updateTransportAgency(agency.key, draft);
                    }
                  },
                  onRemove: () => cubit.removeTransportAgency(agency.key),
                ),
              )
              .toList(),
        );
    }
  }
}

class _EntryList extends StatelessWidget {
  final bool isEmpty;
  final String emptyMessage;
  final String addLabel;
  final VoidCallback onAdd;
  final List<Widget> children;

  const _EntryList({
    required this.isEmpty,
    required this.emptyMessage,
    required this.addLabel,
    required this.onAdd,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            decoration: BoxDecoration(
              color: AppColors.SURFACE_VARIANT,
              borderRadius: BorderRadius.circular(AppRadius.LG),
            ),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(height: 1.5),
            ),
          )
        else
          for (final child in children) ...[
            child,
            const SizedBox(height: AppSpacing.SM8),
          ],
        const SizedBox(height: AppSpacing.SM8),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: AppSizes.ICON_MD),
          label: Text(addLabel, style: AppTypography.button),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.PRIMARY,
            minimumSize: const Size(
              AppSizes.BUTTON_MIN_WIDTH,
              AppSizes.BUTTON_HEIGHT,
            ),
            side: const BorderSide(color: AppColors.PRIMARY),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.MD),
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
