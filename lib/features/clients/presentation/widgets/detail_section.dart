import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final String emptyMessage;
  final List<Widget> children;

  const DetailSection({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.emptyMessage,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.ICON_MD, color: AppColors.PRIMARY),
                const SizedBox(width: AppSpacing.SM8),
                Expanded(child: Text(title, style: AppTypography.labelMedium)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.SM8,
                    vertical: AppSpacing.XXS2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.SURFACE_VARIANT,
                    borderRadius: BorderRadius.circular(AppRadius.FULL),
                  ),
                  child: Text('$count', style: AppTypography.labelSmall),
                ),
              ],
            ),
          ),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.MD16,
                0,
                AppSpacing.MD16,
                AppSpacing.MD16,
              ),
              child: Text(emptyMessage, style: AppTypography.bodySmall),
            )
          else
            for (int index = 0; index < children.length; index++) ...[
              const Divider(
                height: AppSizes.HAIRLINE,
                color: AppColors.HAIRLINE,
              ),
              children[index],
            ],
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isMain;

  const DetailRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium,
                ),
              ),
              if (isMain) ...[
                const SizedBox(width: AppSpacing.SM8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.XS6,
                    vertical: AppSpacing.XXS2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.PRIMARY_SURFACE,
                    borderRadius: BorderRadius.circular(AppRadius.XS),
                  ),
                  child: Text(
                    AppStrings.CLIENT_MAIN,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.PRIMARY,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.XS4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
