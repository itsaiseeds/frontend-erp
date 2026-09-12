import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';
import '../../../../core/widgets/inputs/otp_input_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static const int _phoneLength = 10;
  static const int _otpLength = 6;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String _otp = '';
  String? _otpError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AppStrings.LOGIN_PHONE_REQUIRED;
    if (trimmed.length != _phoneLength) return AppStrings.LOGIN_PHONE_INVALID;
    return null;
  }

  String? _otpValidationError() {
    if (_otp.isEmpty) return AppStrings.LOGIN_OTP_REQUIRED;
    if (_otp.length != _otpLength) return AppStrings.LOGIN_OTP_INVALID;
    return null;
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final otpError = _otpValidationError();
    final isFormValid = _formKey.currentState?.validate() ?? false;

    setState(() => _otpError = otpError);

    if (!isFormValid || otpError != null) return;

    context.read<AuthBloc>().add(
      AuthLoginSubmitted(phoneNumber: _phoneController.text.trim(), otp: _otp),
    );
  }

  void _onOtpChanged(String value) {
    _otp = value;
    if (_otpError != null) setState(() => _otpError = null);
  }

  void _onOtpCompleted(String value) {
    _otp = value;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final bool isLoading = state.status == AuthStatus.loading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.LOGIN_SUBHEADING,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.LG24),
              AppTextField(
                controller: _phoneController,
                label: AppStrings.PHONE_NUMBER,
                labelStyle: AppTypography.labelStrong,
                hint: AppStrings.LOGIN_PHONE_HINT,
                prefixText: AppStrings.PHONE_COUNTRY_CODE_IN,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_phoneLength),
                ],
                validator: _validatePhone,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.MD16),
              const _FieldLabelBlock(
                label: AppStrings.AUTHENTICATION_CODE,
                helper: AppStrings.LOGIN_OTP_HELPER,
              ),
              const SizedBox(height: AppSpacing.SM8),
              OtpInputField(
                length: _otpLength,
                enabled: !isLoading,
                errorText: _otpError,
                onChanged: _onOtpChanged,
                onCompleted: _onOtpCompleted,
              ),
              const SizedBox(height: AppSpacing.LG24),
              PrimaryButton(
                label: AppStrings.SIGN_IN,
                isLoading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.SMD12),
              const _SecureNote(),
            ],
          ),
        );
      },
    );
  }
}

class _FieldLabelBlock extends StatelessWidget {
  final String label;
  final String helper;

  const _FieldLabelBlock({required this.label, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.labelStrong),
        const SizedBox(height: AppSpacing.XS4),
        Text(helper, style: AppTypography.caption),
      ],
    );
  }
}

class _SecureNote extends StatelessWidget {
  const _SecureNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_outline,
          size: AppSizes.ICON_SM,
          color: AppColors.TEXT_DISABLED,
        ),
        const SizedBox(width: AppSpacing.XS4),
        Flexible(
          child: Text(
            AppStrings.LOGIN_SECURE_NOTE,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.TEXT_DISABLED,
            ),
          ),
        ),
      ],
    );
  }
}
