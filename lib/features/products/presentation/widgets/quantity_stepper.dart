import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// ADD until the first tap, then a - count + control, as shopping apps do.
class QuantityStepper extends StatelessWidget {
  static const Duration _duration = Duration(milliseconds: 180);

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Defaults to the compact card label; the detail screen spells it out.
  final String? addLabel;

  /// A filled button reads as the primary action on the detail screen; the
  /// grid cards keep the lighter outlined pill.
  final bool isFilled;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.addLabel,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.STEPPER_HEIGHT,
      child: AnimatedSwitcher(
        duration: _duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: quantity == 0
            ? _AddButton(
                key: const ValueKey('add'),
                onTap: onAdd,
                label: addLabel ?? AppStrings.PRODUCT_ADD,
                isFilled: isFilled,
              )
            : _Stepper(
                key: const ValueKey('stepper'),
                quantity: quantity,
                onAdd: onAdd,
                onRemove: onRemove,
              ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isFilled;

  const _AddButton({
    super.key,
    required this.onTap,
    required this.label,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFilled ? AppColors.PRIMARY : AppColors.SURFACE,
          border: Border.all(
            color: AppColors.PRIMARY,
            width: AppSizes.BORDER_MEDIUM,
          ),
          borderRadius: BorderRadius.circular(AppRadius.MD),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isFilled ? AppColors.TEXT_ON_PRIMARY : AppColors.PRIMARY,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _Stepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.PRIMARY,
          border: Border.all(
            color: AppColors.PRIMARY,
            width: AppSizes.BORDER_MEDIUM,
          ),
          borderRadius: BorderRadius.circular(AppRadius.MD),
        ),
        // A fixed-width count rather than Expanded: the stepper is dropped
        // into rows with no bounded width, where a flex child cannot resolve.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepperButton(icon: Icons.remove_rounded, onTap: onRemove),
            SizedBox(
              width: AppSizes.STEPPER_COUNT_WIDTH,
              child: Center(
                child: Text(
                  '$quantity',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
              ),
            ),
            _StepperButton(icon: Icons.add_rounded, onTap: onAdd),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppSizes.STEPPER_BUTTON,
        height: AppSizes.STEPPER_HEIGHT,
        child: Icon(
          icon,
          size: AppSizes.ICON_MD,
          color: AppColors.TEXT_ON_PRIMARY,
        ),
      ),
    );
  }
}
