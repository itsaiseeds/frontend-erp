import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/client.dart';
import '../../data/models/client_status.dart';
import 'client_status_badge.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientCard({super.key, required this.client, this.onTap});

  String get _monogram {
    final String trimmed = client.companyName.trim();
    if (trimmed.isEmpty) return '?';
    final List<String> words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words[0].characters.first + words[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = client.status == ClientStatus.verificationPending;

    return Material(
      color: AppColors.SURFACE,
      borderRadius: BorderRadius.circular(AppRadius.XL),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.PRIMARY_SURFACE,
        highlightColor: AppColors.PRIMARY_SURFACE,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.BORDER),
            borderRadius: BorderRadius.circular(AppRadius.XL),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: AppSizes.CLIENT_CARD_ACCENT,
                  color: isPending ? AppColors.WARNING : AppColors.PRIMARY,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.MD16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: AppSizes.CLIENT_AVATAR,
                              height: AppSizes.CLIENT_AVATAR,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.PRIMARY_SURFACE,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.LG,
                                ),
                              ),
                              child: Text(
                                _monogram,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.PRIMARY,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.SMD12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    client.companyName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.XS6),
                                  ClientStatusBadge(status: client.status),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.SMD12),
                        const Divider(
                          height: AppSizes.HAIRLINE,
                          color: AppColors.HAIRLINE,
                        ),
                        const SizedBox(height: AppSpacing.SMD12),
                        _MetaLine(
                          icon: Icons.location_on_outlined,
                          text:
                              client.primaryAddress?.formatted ??
                              AppStrings.CLIENT_NO_ADDRESS,
                        ),
                        const SizedBox(height: AppSpacing.SM8),
                        _MetaLine(
                          icon: Icons.person_outline_rounded,
                          text: _contactLine,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _contactLine {
    final contact = client.primaryContact;
    if (contact == null) return AppStrings.CLIENT_NO_CONTACT;
    return [
      contact.name,
      contact.phoneNumber,
    ].where((part) => part.isNotEmpty).join(' · ');
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.XXS2),
          child: Icon(
            icon,
            size: AppSizes.CLIENT_META_ICON,
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
        const SizedBox(width: AppSpacing.XS6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
