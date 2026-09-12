import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/client_status.dart';

class ClientStatusBadge extends StatelessWidget {
  final ClientStatus status;

  const ClientStatusBadge({super.key, required this.status});

  Color get _foreground {
    switch (status) {
      case ClientStatus.verified:
        return AppColors.SUCCESS;
      case ClientStatus.verificationPending:
        return AppColors.WARNING;
      case ClientStatus.unknown:
        return AppColors.TEXT_SECONDARY;
    }
  }

  Color get _background {
    switch (status) {
      case ClientStatus.verified:
        return AppColors.SUCCESS_LIGHT;
      case ClientStatus.verificationPending:
        return AppColors.WARNING_LIGHT;
      case ClientStatus.unknown:
        return AppColors.SURFACE_VARIANT;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SM8,
        vertical: AppSpacing.XXS2,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.FULL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.CLIENT_STATUS_DOT,
            height: AppSizes.CLIENT_STATUS_DOT,
            decoration: BoxDecoration(
              color: _foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.XS6),
          Text(
            ClientStatusX.labelOf(status),
            style: AppTypography.labelSmall.copyWith(color: _foreground),
          ),
        ],
      ),
    );
  }
}
