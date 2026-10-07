import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../godown/data/models/inward_raw_material.dart';
import '../data/models/lab_testing.dart';
import 'bloc/lab_testings_cubit.dart';
import 'widgets/lab_result_badge.dart';
import 'lab_test_form_screen.dart';

/// One lab test report: what was counted, what the server computed, and who
/// gave the verdict. Edit lives here -- a report can be corrected at any
/// time, and a changed verdict moves the lot between In Use and Rejected.
class LabTestingDetailScreen extends StatefulWidget {
  final LabTesting test;
  final LabTestingsCubit cubit;

  const LabTestingDetailScreen({
    super.key,
    required this.test,
    required this.cubit,
  });

  static Future<void> push(
    BuildContext context, {
    required LabTesting test,
    required LabTestingsCubit cubit,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LabTestingDetailScreen(test: test, cubit: cubit),
      ),
    );
  }

  @override
  State<LabTestingDetailScreen> createState() => _LabTestingDetailScreenState();
}

class _LabTestingDetailScreenState extends State<LabTestingDetailScreen> {
  late LabTesting _test;

  @override
  void initState() {
    super.initState();
    _test = widget.test;
  }

  Future<void> _edit(BuildContext context) async {
    final LabTesting? updated = await LabTestFormScreen.pushEdit(
      context,
      test: _test,
    );
    if (updated != null && mounted) setState(() => _test = updated);
    widget.cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final LabTesting test = _test;

    return Scaffold(
      backgroundColor: AppColors.BACKGROUND,
      appBar: AppBar(
        backgroundColor: AppColors.SURFACE,
        surfaceTintColor: AppColors.TRANSPARENT,
        elevation: 0,
        titleSpacing: 0,
        leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: AppSizes.ICON_XL,
            color: AppColors.TEXT_PRIMARY,
          ),
        ),
        title: Text(
          AppStrings.LAB_TEST_DETAIL_TITLE,
          style: AppTypography.titleMedium,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _edit(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.PRIMARY),
            icon: const Icon(
              Icons.edit_outlined,
              size: AppSizes.ICON_MD,
              color: AppColors.PRIMARY,
            ),
            label: Text(
              AppStrings.LAB_TEST_EDIT,
              style: AppTypography.button.copyWith(color: AppColors.PRIMARY),
            ),
          ),
          const SizedBox(width: AppSpacing.XS6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.SMD12,
          AppSpacing.SMD12,
          AppSpacing.SMD12,
          AppSizes.ORDER_LIST_BOTTOM_INSET,
        ),
        children: [
          _HeaderCard(test: test),
          const SizedBox(height: AppSpacing.SMD12),
          _CountsCard(test: test),
          const SizedBox(height: AppSpacing.SMD12),
          _ResultCard(test: test),
        ],
      ),
    );
  }
}

/// Who, what and how much, headed by a tinted band carrying the product name
/// and the verdict -- the same weight the godown lot detail gives its header.
class _HeaderCard extends StatelessWidget {
  final LabTesting test;

  const _HeaderCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final InwardRawMaterial lot = test.inwardRawMaterial;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            color: AppColors.PRIMARY_SURFACE,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    lot.product.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.TEXT_PRIMARY,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.SM8),
                LabResultBadge(result: test.result),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(
                  label: AppStrings.LAB_TEST_FIELD_PARTY,
                  value: lot.party.name,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.LAB_TEST_FIELD_LOT_NO,
                  value: lot.lotNo,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.LAB_TEST_FIELD_QUANTITY_KG,
                  value: '${lot.quantityKg} ${AppStrings.KG_LABEL}',
                  valueColor: AppColors.PRIMARY,
                  isValueStrong: true,
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.LAB_TEST_FIELD_TESTED_BY,
                  value: test.testedBy?.name ?? '',
                ),
                const _RowSeparator(),
                _DetailRow(
                  label: AppStrings.LAB_TEST_FIELD_TESTED_AT,
                  value: DateFormatter.dayTimeFull(test.testedAt),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The grow-out inputs and the two server-computed read-outs.
class _CountsCard extends StatelessWidget {
  final LabTesting test;

  const _CountsCard({required this.test});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.MD16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(
              label: AppStrings.LAB_TEST_FIELD_NUMBER_OF_PLANTS,
              value: '${test.numberOfPlants}',
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.LAB_TEST_FIELD_FEMALE_COUNT,
              value: '${test.femaleCount}',
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.LAB_TEST_FIELD_OT_COUNT,
              value: '${test.otCount}',
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.LAB_TEST_GENETICAL_IMPURITY,
              value: '${test.geneticalImpurity}%',
            ),
            const _RowSeparator(),
            _DetailRow(
              label: AppStrings.LAB_TEST_GROW_OUT_TEST,
              value: '${test.growOutTest}%',
              valueColor: AppColors.PRIMARY,
              isValueStrong: true,
            ),
            if (test.comment.trim().isNotEmpty) ...[
              const _RowSeparator(),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.SMD12,
                  bottom: AppSpacing.MD16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.LAB_TEST_FIELD_COMMENT,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.TEXT_SECONDARY,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.SMD12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        test.comment,
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.TEXT_PRIMARY,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The verdict alone, tinted to match it -- so a Pass / Fail decision is
/// readable from across the screen without hunting the mini pill in the band.
class _ResultCard extends StatelessWidget {
  final LabTesting test;

  const _ResultCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final Color color = test.isPass
        ? AppColors.SUCCESS
        : test.isFail
        ? AppColors.ERROR
        : AppColors.WARNING;
    final Color background = test.isPass
        ? AppColors.SUCCESS_LIGHT
        : test.isFail
        ? AppColors.ERROR_LIGHT
        : AppColors.WARNING_LIGHT;

    return _Card(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.MD16),
        color: background,
        child: Row(
          children: [
            Icon(
              test.isPass
                  ? Icons.check_circle_outline_rounded
                  : test.isFail
                  ? Icons.cancel_outlined
                  : Icons.hourglass_top_rounded,
              size: AppSizes.ICON_XL,
              color: color,
            ),
            const SizedBox(width: AppSpacing.SMD12),
            Expanded(
              child: Text(
                test.result ?? AppStrings.CLIENT_STATUS_PENDING,
                style: AppTypography.titleMedium.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isValueStrong;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isValueStrong = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final String shown = value.trim().isEmpty
        ? AppStrings.ORDER_NO_DATE
        : value;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.SMD12,
        bottom: isLast ? AppSpacing.MD16 : AppSpacing.SMD12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.SMD12),
          Expanded(
            flex: 2,
            child: Text(
              shown,
              textAlign: TextAlign.right,
              style:
                  (isValueStrong
                          ? AppTypography.labelStrong
                          : AppTypography.bodyMedium)
                      .copyWith(color: valueColor ?? AppColors.TEXT_PRIMARY),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowSeparator extends StatelessWidget {
  const _RowSeparator();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSizes.DIVIDER_THIN,
      thickness: AppSizes.DIVIDER_THIN,
      color: AppColors.DIVIDER,
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}