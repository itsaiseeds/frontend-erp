import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/loaders/dots_loader.dart';
import '../data/analytics_repository.dart';
import '../data/models/analytics_summary.dart';
import 'bloc/analytics_cubit.dart';
import 'widgets/analytics_charts.dart';

/// The salesperson's own numbers for a chosen window.
class AnalyticsDashboard extends StatelessWidget {
  final String userName;

  const AnalyticsDashboard({super.key, this.userName = ''});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnalyticsCubit>(
      create: (context) => AnalyticsCubit(
        repository: AnalyticsRepository(apiClient: context.read<ApiClient>()),
      )..load(),
      child: _DashboardBody(userName: userName),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final String userName;

  const _DashboardBody({required this.userName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        final AnalyticsCubit cubit = context.read<AnalyticsCubit>();

        return RefreshIndicator(
          color: AppColors.PRIMARY,
          onRefresh: cubit.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.SMD12,
              AppSpacing.SMD12,
              AppSpacing.SMD12,
              AppSpacing.LG24,
            ),
            children: [
              _Greeting(userName: userName),
              const SizedBox(height: AppSpacing.SMD12),
              _RangePicker(
                selected: state.range,
                enabled: !state.isFirstLoad,
                onSelected: cubit.selectRange,
              ),
              const SizedBox(height: AppSpacing.SMD12),
              ..._buildContent(context, state, cubit),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    AnalyticsState state,
    AnalyticsCubit cubit,
  ) {
    if (state.isFirstLoad) {
      return const [
        SizedBox(height: AppSpacing.XL40),
        Center(child: DotsLoader()),
      ];
    }

    if (state.status == AnalyticsStatus.failure && state.summary == null) {
      return [
        const SizedBox(height: AppSpacing.LG24),
        _Message(
          icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          title: AppStrings.ANALYTICS_LOAD_FAILED,
          body: state.errorMessage ?? '',
          onRetry: cubit.refresh,
        ),
      ];
    }

    final AnalyticsSummary? summary = state.summary;
    if (summary == null) return const [];

    if (summary.isEmpty) {
      return const [
        SizedBox(height: AppSpacing.LG24),
        _Message(
          icon: Icons.insights_outlined,
          title: AppStrings.ANALYTICS_EMPTY_TITLE,
          body: AppStrings.ANALYTICS_EMPTY_BODY,
        ),
      ];
    }

    return [
      // Dimmed while a new window loads: the old numbers stay readable but
      // are visibly stale, which beats blanking the page.
      Opacity(
        opacity: state.isRefreshing ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeadlineRow(summary: summary),
            const SizedBox(height: AppSpacing.SMD12),
            if (summary.orders.total > 0) ...[
              _Card(
                title: AppStrings.ANALYTICS_ORDERS_TITLE,
                child: OrderStatusDonut(breakdown: summary.orders),
              ),
              const SizedBox(height: AppSpacing.SMD12),
            ],
            _Card(
              title: AppStrings.ANALYTICS_CLIENTS_TITLE,
              child: _ClientSplit(clients: summary.clients),
            ),
            const SizedBox(height: AppSpacing.SMD12),
            _Card(
              title: AppStrings.ANALYTICS_TOP_PRODUCTS_TITLE,
              child: ProductWeightBars(products: summary.products),
            ),
          ],
        ),
      ),
    ];
  }
}

class _Greeting extends StatelessWidget {
  final String userName;

  const _Greeting({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userName.trim().isEmpty
              ? AppStrings.ANALYTICS_GREETING
              : '${AppStrings.ANALYTICS_GREETING}, ${userName.trim()}',
          style: AppTypography.titleMedium,
        ),
      ],
    );
  }
}

class _RangePicker extends StatelessWidget {
  final AnalyticsRange selected;
  final bool enabled;
  final ValueChanged<AnalyticsRange> onSelected;

  const _RangePicker({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final AnalyticsRange range in AnalyticsRange.values) ...[
            _RangeChip(
              label: range.label,
              isSelected: range == selected,
              enabled: enabled,
              onTap: () => onSelected(range),
            ),
            const SizedBox(width: AppSpacing.SM8),
          ],
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.SMD12,
          vertical: AppSpacing.SM8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.PRIMARY : AppColors.SURFACE,
          border: Border.all(
            color: isSelected ? AppColors.PRIMARY : AppColors.BORDER,
          ),
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.TEXT_ON_PRIMARY
                : AppColors.TEXT_SECONDARY,
          ),
        ),
      ),
    );
  }
}

/// The two numbers worth seeing before any chart.
class _HeadlineRow extends StatelessWidget {
  final AnalyticsSummary summary;

  const _HeadlineRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final int delivered = summary.orders.byStatus['DELIVERED'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.receipt_long_outlined,
            value: '${summary.orders.total}',
            label: AppStrings.ANALYTICS_ORDERS_TOTAL,
            caption:
                '$delivered ${AppStrings.ANALYTICS_DELIVERED.toLowerCase()}',
            tone: AppColors.PRIMARY,
          ),
        ),
        const SizedBox(width: AppSpacing.SMD12),
        Expanded(
          child: _StatTile(
            icon: Icons.groups_outlined,
            value: '${summary.clients.total}',
            label: AppStrings.ANALYTICS_CLIENTS_TOTAL,
            caption:
                '${summary.clients.verifiedCount} '
                '${AppStrings.ANALYTICS_VERIFIED.toLowerCase()}',
            tone: AppColors.INFO,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String caption;
  final Color tone;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.caption,
    required this.tone,
  });

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
          Icon(icon, size: AppSizes.ICON_LG, color: tone),
          const SizedBox(height: AppSpacing.SM8),
          Text(value, style: AppTypography.headingSmall),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
          const SizedBox(height: AppSpacing.XS4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _ClientSplit extends StatelessWidget {
  final ClientBreakdown clients;

  const _ClientSplit({required this.clients});

  @override
  Widget build(BuildContext context) {
    final int total = clients.total;
    final double verifiedFraction = total == 0
        ? 0
        : clients.verifiedCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.FULL),
          child: LinearProgressIndicator(
            value: verifiedFraction,
            minHeight: AppSpacing.SMD12,
            backgroundColor: AppColors.WARNING.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.SUCCESS,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.SMD12),
        Row(
          children: [
            Expanded(
              child: _Tally(
                color: AppColors.SUCCESS,
                label: AppStrings.ANALYTICS_VERIFIED,
                count: clients.verifiedCount,
              ),
            ),
            Expanded(
              child: _Tally(
                color: AppColors.WARNING,
                label: AppStrings.ANALYTICS_PENDING,
                count: clients.pendingCount,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tally extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _Tally({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSpacing.SM8,
          height: AppSpacing.SM8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.SM8),
        Text('$count', style: AppTypography.labelStrong),
        const SizedBox(width: AppSpacing.XS4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

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
          Text(title, style: AppTypography.labelStrong),
          const SizedBox(height: AppSpacing.SMD12),
          child,
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
        const SizedBox(height: AppSpacing.SMD12),
        Text(title, textAlign: TextAlign.center, style: AppTypography.titleMedium),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.XS4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.MD16),
          PrimaryButton(label: AppStrings.RETRY, onPressed: onRetry),
        ],
      ],
    );
  }
}
