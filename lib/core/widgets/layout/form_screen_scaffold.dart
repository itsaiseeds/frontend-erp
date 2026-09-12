import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/primary_button.dart';
import 'dismiss_keyboard.dart';
import 'keyboard_aware_footer.dart';

class FormScreenScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isBusy;
  final bool hasUnsavedChanges;
  final Widget child;

  const FormScreenScaffold({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
    this.subtitle,
    this.isBusy = false,
    this.hasUnsavedChanges = false,
  });

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!hasUnsavedChanges) return true;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.OVERLAY,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.SURFACE,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.SEGMENT),
        ),
        title: Text(
          AppStrings.ENTRY_DISCARD_TITLE,
          style: AppTypography.titleMedium,
        ),
        content: Text(
          AppStrings.ENTRY_DISCARD_BODY,
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

  Future<void> _handleBack(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (await _confirmDiscard(context) && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
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
            onPressed: () => _handleBack(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.titleMedium),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.caption),
            ],
          ),
        ),
        body: DismissKeyboard(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppSpacing.MD16),
                  child: child,
                ),
              ),
              KeyboardAwareFooter(
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: actionLabel,
                    isLoading: isBusy,
                    onPressed: onAction,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
