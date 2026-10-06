import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/loaders/dots_loader.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../analytics/data/models/analytics_summary.dart';
import '../../analytics/presentation/bloc/analytics_cubit.dart';
import '../../auth/presentation/bloc/session_cubit.dart';

/// Who the salesperson is, and what they have done lately.
///
/// The figures come from the same analytics endpoint the dashboard uses, so
/// the page says something useful rather than only echoing the login.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnalyticsCubit>(
      create: (context) =>
          AnalyticsCubit(
            repository: AnalyticsRepository(
              apiClient: context.read<ApiClient>(),
            ),
          )..selectRange(AnalyticsRange.quarter),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, sessionState) {
        final session = sessionState.session;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.SMD12,
            AppSpacing.SMD12,
            AppSpacing.SMD12,
            AppSpacing.LG24,
          ),
          children: [
            _IdentityCard(
              name: session?.name ?? '',
              phoneNumber: session?.phoneNumber ?? '',
            ),
            const SizedBox(height: AppSpacing.SMD12),
            const _NumbersCard(),
            const SizedBox(height: AppSpacing.SMD12),
            _DetailsCard(
              phoneNumber: session?.phoneNumber ?? '',
              role: session?.role ?? '',
            ),
          ],
        );
      },
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String phoneNumber;

  const _IdentityCard({required this.name, required this.phoneNumber});

  /// Up to two initials, so a long name still fits the circle.
  String get _initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.PRIMARY,
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.PROFILE_AVATAR,
            height: AppSizes.PROFILE_AVATAR,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.SURFACE,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.PRIMARY,
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
                  name.trim().isEmpty ? AppStrings.DRAWER_PROFILE : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.TEXT_ON_PRIMARY,
                  ),
                ),
                if (phoneNumber.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.XS4),
                  Text(
                    phoneNumber,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.TEXT_ON_PRIMARY.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumbersCard extends StatelessWidget {
  const _NumbersCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        final AnalyticsSummary? summary = state.summary;

        return _Card(
          title: AppStrings.PROFILE_LIFETIME_TITLE,
          caption: AppStrings.PROFILE_LIFETIME_CAPTION,
          child: state.isFirstLoad
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.MD16),
                  child: Center(child: DotsLoader()),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _Figure(
                        value: '${summary?.orders.total ?? 0}',
                        label: AppStrings.PROFILE_ORDERS,
                        tone: AppColors.PRIMARY,
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        value:
                            '${summary?.orders.byStatus['DELIVERED'] ?? 0}',
                        label: AppStrings.PROFILE_DELIVERED,
                        tone: AppColors.SUCCESS,
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        value: '${summary?.clients.total ?? 0}',
                        label: AppStrings.PROFILE_CLIENTS,
                        tone: AppColors.INFO,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Figure extends StatelessWidget {
  final String value;
  final String label;
  final Color tone;

  const _Figure({
    required this.value,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(color: tone),
        ),
        const SizedBox(height: AppSpacing.XS4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.TEXT_SECONDARY,
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String phoneNumber;
  final String role;

  const _DetailsCard({required this.phoneNumber, required this.role});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: AppStrings.PROFILE_DETAILS_TITLE,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow(
            icon: Icons.phone_outlined,
            label: AppStrings.PROFILE_PHONE,
            value: phoneNumber,
          ),
          const SizedBox(height: AppSpacing.SMD12),
          _DetailRow(
            icon: Icons.badge_outlined,
            label: AppStrings.PROFILE_ROLE,
            value: role.trim().isEmpty
                ? AppStrings.PROFILE_ROLE_SALESPERSON
                : role,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.ICON_LG, color: AppColors.TEXT_SECONDARY),
        const SizedBox(width: AppSpacing.SMD12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.labelStrong,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget child;

  const _Card({required this.title, required this.child, this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.SMD12),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.LG),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.labelStrong)),
              if (caption != null)
                Text(
                  caption!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.TEXT_DISABLED,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.SMD12),
          child,
        ],
      ),
    );
  }
}
