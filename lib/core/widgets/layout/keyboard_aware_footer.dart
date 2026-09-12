import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class KeyboardAwareFooter extends StatelessWidget {
  final Widget child;
  final bool applyKeyboardInset;

  const KeyboardAwareFooter({
    super.key,
    required this.child,
    this.applyKeyboardInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final double inset = applyKeyboardInset
        ? MediaQuery.of(context).viewInsets.bottom
        : 0;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.SURFACE,
        border: Border(top: BorderSide(color: AppColors.HAIRLINE)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.MD16,
        right: AppSpacing.MD16,
        top: AppSpacing.SMD12,
        bottom: AppSpacing.SMD12 + inset,
      ),
      child: SafeArea(top: false, bottom: !isKeyboardOpen, child: child),
    );
  }
}
