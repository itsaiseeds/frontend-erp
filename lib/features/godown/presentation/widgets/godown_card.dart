import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// One record card shared by every godown list/stock screen: an icon tile and
/// title up top, an optional tag row (a dot-marked label plus a monospace
/// code pill), then a tinted two-column footer -- mirrors the catalogue-style
/// card the admin asked to match, rather than the plain table this replaces.
class GodownCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? tagLabel;
  final Color? tagColor;
  final String? codeLabel;
  final Widget? trailing;
  final List<GodownCardStat> stats;
  final VoidCallback? onTap;

  const GodownCard({
    super.key,
    required this.icon,
    required this.title,
    this.tagLabel,
    this.tagColor,
    this.codeLabel,
    this.trailing,
    this.stats = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.SURFACE,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.PRIMARY_SURFACE,
        highlightColor: AppColors.PRIMARY_SURFACE,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.SMD12,
                AppSpacing.SMD12,
                AppSpacing.SMD12,
                AppSpacing.SM8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppSizes.ORDER_ICON_BOX,
                    height: AppSizes.ORDER_ICON_BOX,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.PRIMARY_SURFACE,
                      borderRadius: BorderRadius.circular(AppRadius.LG),
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.ICON_MD,
                      color: AppColors.PRIMARY,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.SMD12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelStrong.copyWith(
                            color: AppColors.TEXT_PRIMARY,
                          ),
                        ),
                        if (tagLabel != null || codeLabel != null) ...[
                          const SizedBox(height: AppSpacing.XS6),
                          _TagRow(
                            tagLabel: tagLabel,
                            tagColor: tagColor ?? AppColors.TEXT_SECONDARY,
                            codeLabel: codeLabel,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.SM8),
                    trailing!,
                  ],
                ],
              ),
            ),
            if (stats.isNotEmpty) _Footer(stats: stats),
          ],
        ),
      ),
    );
  }
}

class GodownCardStat extends Equatable {
  final String label;
  final String value;
  final Color? valueColor;

  const GodownCardStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  List<Object?> get props => [label, value, valueColor];
}

class _TagRow extends StatelessWidget {
  final String? tagLabel;
  final Color tagColor;
  final String? codeLabel;

  const _TagRow({
    required this.tagLabel,
    required this.tagColor,
    required this.codeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.SM8,
      runSpacing: AppSpacing.XXS2,
      children: [
        if (tagLabel != null && tagLabel!.trim().isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSizes.CLIENT_STATUS_DOT,
                height: AppSizes.CLIENT_STATUS_DOT,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.XS6),
              Flexible(
                child: Text(
                  tagLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
              ),
            ],
          ),
        if (codeLabel != null && codeLabel!.trim().isNotEmpty)
          Text(
            codeLabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.TEXT_TERTIARY,
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final List<GodownCardStat> stats;

  const _Footer({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.SMD12,
        vertical: AppSpacing.SM8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.BACKGROUND,
        border: Border(top: BorderSide(color: AppColors.BORDER)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.SMD12),
            Expanded(child: _Stat(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final GodownCardStat stat;

  const _Stat({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stat.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.TEXT_TERTIARY,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.XXS2),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: stat.valueColor ?? AppColors.TEXT_PRIMARY,
          ),
        ),
      ],
    );
  }
}
