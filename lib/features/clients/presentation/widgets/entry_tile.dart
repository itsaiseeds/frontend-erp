import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class EntryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isMain;
  final VoidCallback? onEdit;
  final VoidCallback onRemove;

  const EntryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    this.isMain = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.SMD12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isMain ? AppColors.PRIMARY : AppColors.BORDER,
              width: isMain ? AppSizes.BORDER_MEDIUM : AppSizes.BORDER_THIN,
            ),
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: AppSizes.ICON_MD,
                color: AppColors.TEXT_SECONDARY,
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null)
                _TileAction(
                  tooltip: AppStrings.CLIENT_EDIT,
                  icon: Icons.edit_outlined,
                  color: AppColors.PRIMARY,
                  background: AppColors.PRIMARY_SURFACE,
                  onPressed: onEdit!,
                ),
              _TileAction(
                tooltip: AppStrings.CLIENT_REMOVE,
                icon: Icons.delete_outline_rounded,
                color: AppColors.ERROR,
                background: AppColors.ERROR_LIGHT,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final Color? background;
  final VoidCallback onPressed;

  const _TileAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.XS4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: background ?? AppColors.TRANSPARENT,
          borderRadius: BorderRadius.circular(AppRadius.MD),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.SM8),
              child: Icon(icon, size: AppSizes.ICON_MD, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
