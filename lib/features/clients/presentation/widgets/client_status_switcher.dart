import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/client_status.dart';

class ClientStatusSwitcher extends StatelessWidget {
  final ClientStatus? selected;
  final ValueChanged<ClientStatus?> onChanged;

  const ClientStatusSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const Duration _duration = Duration(milliseconds: 260);
  static const Curve _curve = Curves.easeOutCubic;

  static const List<ClientStatus?> _options = [
    null,
    ClientStatus.verified,
    ClientStatus.verificationPending,
  ];

  static String _labelFor(ClientStatus? status) {
    switch (status) {
      case null:
        return AppStrings.CLIENT_VIEW_ALL;
      case ClientStatus.verified:
        return AppStrings.CLIENT_STATUS_VERIFIED;
      case ClientStatus.verificationPending:
        return AppStrings.CLIENT_STATUS_PENDING;
      case ClientStatus.unknown:
        return AppStrings.CLIENT_STATUS_UNKNOWN;
    }
  }

  static Color _accentFor(ClientStatus? status) {
    switch (status) {
      case null:
        return AppColors.PRIMARY;
      case ClientStatus.verified:
        return AppColors.SUCCESS;
      case ClientStatus.verificationPending:
        return AppColors.WARNING;
      case ClientStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _options
        .indexOf(selected)
        .clamp(0, _options.length - 1);

    return Container(
      height: AppSizes.CLIENT_SEGMENT_HEIGHT,
      padding: const EdgeInsets.all(AppSpacing.XS4),
      decoration: BoxDecoration(
        color: AppColors.SURFACE_VARIANT,
        borderRadius: BorderRadius.circular(AppRadius.SEGMENT),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = constraints.maxWidth / _options.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                left: segmentWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.SURFACE,
                    borderRadius: BorderRadius.circular(AppRadius.LG),
                  ),
                ),
              ),
              Row(
                children: List.generate(_options.length, (index) {
                  final ClientStatus? option = _options[index];

                  return Expanded(
                    child: _Segment(
                      label: _labelFor(option),
                      accent: _accentFor(option),
                      isSelected: index == selectedIndex,
                      showDot: option != null,
                      duration: _duration,
                      curve: _curve,
                      onTap: () => onChanged(option),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final Color accent;
  final bool isSelected;
  final bool showDot;
  final Duration duration;
  final Curve curve;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.accent,
    required this.isSelected,
    required this.showDot,
    required this.duration,
    required this.curve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = isSelected ? accent : AppColors.TEXT_SECONDARY;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot)
              AnimatedSize(
                duration: duration,
                curve: curve,
                child: SizedBox(
                  width: isSelected
                      ? AppSizes.CLIENT_STATUS_DOT + AppSpacing.XS6
                      : 0,
                  child: AnimatedOpacity(
                    duration: duration,
                    curve: curve,
                    opacity: isSelected ? 1 : 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: AppSizes.CLIENT_STATUS_DOT,
                          height: AppSizes.CLIENT_STATUS_DOT,
                          decoration: BoxDecoration(
                            color: foreground,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.XS6),
                      ],
                    ),
                  ),
                ),
              ),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: duration,
                curve: curve,
                style: isSelected
                    ? AppTypography.labelMedium.copyWith(color: foreground)
                    : AppTypography.bodySmall,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
