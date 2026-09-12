import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final String? prefixText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? labelStyle;
  final TextInputAction? textInputAction;
  final bool isRequired;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.labelStyle,
    this.textInputAction,
    this.isRequired = false,
    this.autofocus = false,
  });

  OutlineInputBorder _border(
    Color color, {
    double width = AppSizes.BORDER_THIN,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.CHIP),
    borderSide: BorderSide(color: color, width: width),
  );

  Widget? _buildPrefix() {
    if (prefixText != null) {
      return _AppTextFieldPrefix(text: prefixText!, enabled: enabled);
    }
    if (prefixIcon != null) {
      return Icon(
        prefixIcon,
        size: AppSizes.ICON_MD,
        color: AppColors.TEXT_SECONDARY,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: labelStyle ?? AppTypography.label,
              children: isRequired
                  ? [
                      TextSpan(
                        text: AppStrings.REQUIRED_MARKER,
                        style: (labelStyle ?? AppTypography.label).copyWith(
                          color: AppColors.ERROR,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.SM8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          enabled: enabled,
          autofocus: autofocus,
          textInputAction: textInputAction,
          style: AppTypography.bodyMedium,
          cursorColor: AppColors.PRIMARY,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.TEXT_DISABLED,
            ),
            filled: true,
            fillColor: enabled ? AppColors.SURFACE : AppColors.SURFACE_VARIANT,
            contentPadding: EdgeInsets.only(
              left: prefixText != null ? AppSpacing.SMD12 : AppSpacing.MD16,
              right: AppSpacing.MD16,
              top: AppSpacing.SMD12,
              bottom: AppSpacing.SMD12,
            ),
            prefixIcon: _buildPrefix(),
            prefixIconConstraints: prefixText != null
                ? const BoxConstraints(
                    minWidth: AppSizes.PHONE_PREFIX_WIDTH,
                    minHeight: AppSizes.INPUT_HEIGHT,
                  )
                : null,
            suffixIcon: suffixIcon,
            border: _border(AppColors.BORDER),
            enabledBorder: _border(AppColors.BORDER),
            focusedBorder: _border(
              AppColors.BORDER_FOCUSED,
              width: AppSizes.BORDER_THICK,
            ),
            disabledBorder: _border(AppColors.BORDER),
            errorBorder: _border(AppColors.ERROR),
            focusedErrorBorder: _border(
              AppColors.ERROR,
              width: AppSizes.BORDER_MEDIUM,
            ),
            errorStyle: AppTypography.caption.copyWith(color: AppColors.ERROR),
          ),
        ),
      ],
    );
  }
}

class _AppTextFieldPrefix extends StatelessWidget {
  final String text;
  final bool enabled;

  const _AppTextFieldPrefix({required this.text, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.SMD12),
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled
                  ? AppColors.TEXT_SECONDARY
                  : AppColors.TEXT_DISABLED,
            ),
          ),
        ),
        Container(
          width: AppSizes.BORDER_THIN,
          height: AppSpacing.MD16,
          color: AppColors.DIVIDER,
        ),
        const SizedBox(width: AppSpacing.SMD12),
      ],
    );
  }
}
