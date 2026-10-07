import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/dialogs/confirmation_dialog.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/layout/dismiss_keyboard.dart';
import '../../godown/data/models/inward_raw_material.dart';
import '../data/lab_tester_repository.dart';
import '../data/models/lab_testing.dart';

/// The verdict form: the grow-out counts plus a live read-out of what the
/// server will compute, and a Pass / Fail choice that confirms before it
/// fires.
///
/// Two entry points -- a lot from the pending queue (submit a new test) or an
/// existing report (edit it). Both share the same fields and rules; only the
/// final call differs (POST vs PATCH). On a lot an admin sent back, the
/// earlier counts are fetched and prefilled so the correction is a short one.
class LabTestFormScreen extends StatefulWidget {
  /// The lot being (re-)tested; null when editing an existing report.
  final InwardRawMaterial? lot;

  /// The report being corrected; null when submitting from the queue.
  final LabTesting? test;

  const LabTestFormScreen({
    super.key,
    this.lot,
    this.test,
  });

  static Future<bool?> push(
    BuildContext context, {
    required InwardRawMaterial lot,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LabTestFormScreen(lot: lot),
      ),
    );
  }

  static Future<LabTesting?> pushEdit(
    BuildContext context, {
    required LabTesting test,
  }) {
    return Navigator.of(context).push<LabTesting>(
      MaterialPageRoute<LabTesting>(
        builder: (_) => LabTestFormScreen(test: test),
      ),
    );
  }

  @override
  State<LabTestFormScreen> createState() => _LabTestFormScreenState();
}

class _LabTestFormScreenState extends State<LabTestFormScreen> {
  final TextEditingController _plantsController = TextEditingController();
  final TextEditingController _femaleController = TextEditingController();
  final TextEditingController _otController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  String? _plantsError;
  String? _femaleError;
  String? _otError;

  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEditing => widget.test != null;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _plantsController.dispose();
    _femaleController.dispose();
    _otController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// An edit starts from the values it carries. A fresh test of a lot that
  /// was tested before (an admin sent it back) fetches that record so the
  /// tester corrects digits rather than retyping them.
  Future<void> _prefill() async {
    final LabTesting? existing = widget.test;
    if (existing != null) {
      _plantsController.text = '${existing.numberOfPlants}';
      _femaleController.text = '${existing.femaleCount}';
      _otController.text = '${existing.otCount}';
      _commentController.text = existing.comment;
      return;
    }

    final LabTestingRef? ref = widget.lot?.labTesting;
    if (ref == null || ref.publicId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final LabTesting prior = await LabTesterRepository(
        apiClient: context.read<ApiClient>(),
      ).fetchLabTesting(ref.publicId);
      if (!mounted) return;
      setState(() {
        _plantsController.text = '${prior.numberOfPlants}';
        _femaleController.text = '${prior.femaleCount}';
        _otController.text = '${prior.otCount}';
        _commentController.text = prior.comment;
      });
    } on ApiException {
      // A re-test that lost its record simply starts empty; the tester can
      // type the counts as usual.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validate() {
    final String plants = _plantsController.text.trim();
    final String female = _femaleController.text.trim();
    final String ot = _otController.text.trim();

    final int? plantsValue = int.tryParse(plants);
    final int? femaleValue = int.tryParse(female);
    final int? otValue = int.tryParse(ot);

    setState(() {
      _plantsError = plants.isEmpty || plantsValue == null
          ? AppStrings.LAB_TEST_VALIDATION_PLANTS
          : (plantsValue <= 0
                ? AppStrings.LAB_TEST_VALIDATION_PLANTS_POSITIVE
                : null);
      _femaleError = female.isEmpty || femaleValue == null
          ? AppStrings.LAB_TEST_VALIDATION_FEMALE
          : null;
      _otError = ot.isEmpty || otValue == null
          ? AppStrings.LAB_TEST_VALIDATION_OT
          : null;
    });

    if (_plantsError != null || _femaleError != null || _otError != null) {
      return false;
    }

    if (femaleValue! + otValue! > plantsValue!) {
      setState(() {
        _plantsError = AppStrings.LAB_TEST_VALIDATION_COUNTS_EXCEED_PLANTS;
      });
      return false;
    }

    return true;
  }

  /// Server-side formula, shown live while the counts are typed. The server
  /// is authoritative -- this is a preview, never what gets stored.
  double? get _impurityPreview {
    final int? plants = int.tryParse(_plantsController.text.trim());
    final int? female = int.tryParse(_femaleController.text.trim());
    final int? ot = int.tryParse(_otController.text.trim());
    if (plants == null ||
        plants <= 0 ||
        female == null ||
        ot == null ||
        female + ot > plants) {
      return null;
    }
    final double impurity = (female + ot) / plants * 100;
    return (impurity * 100).round() / 100;
  }

  double? get _growOutPreview {
    final double? impurity = _impurityPreview;
    if (impurity == null) return null;
    return double.parse((100 - impurity).toStringAsFixed(2));
  }

  Future<void> _verdict(String result) async {
    if (_isSaving || !_validate()) return;

    final bool confirmed = await ConfirmationDialog.show(
      context,
      title: result == 'Pass'
          ? AppStrings.LAB_TEST_CONFIRM_PASS_TITLE
          : AppStrings.LAB_TEST_CONFIRM_FAIL_TITLE,
      body: result == 'Pass'
          ? AppStrings.LAB_TEST_CONFIRM_PASS_BODY
          : AppStrings.LAB_TEST_CONFIRM_FAIL_BODY,
      confirmLabel: result == 'Pass'
          ? AppStrings.LAB_TEST_PASS
          : AppStrings.LAB_TEST_FAIL,
      confirmColor: result == 'Pass' ? AppColors.SUCCESS : AppColors.ERROR,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final LabTesterRepository repository = LabTesterRepository(
      apiClient: context.read<ApiClient>(),
    );

    try {
      if (_isEditing) {
        final LabTesting updated = await repository.updateLabTesting(
          publicId: widget.test!.publicId,
          numberOfPlants: int.parse(_plantsController.text.trim()),
          femaleCount: int.parse(_femaleController.text.trim()),
          otCount: int.parse(_otController.text.trim()),
          result: result,
          comment: _commentController.text,
        );
        if (!mounted) return;
        ToastUtils.showSuccess(context, AppStrings.LAB_TEST_UPDATED);
        Navigator.of(context).pop(updated);
        return;
      }

      await repository.submitLabTest(
        inwardRawMaterialPublicId: widget.lot!.publicId,
        numberOfPlants: int.parse(_plantsController.text.trim()),
        femaleCount: int.parse(_femaleController.text.trim()),
        otCount: int.parse(_otController.text.trim()),
        result: result,
        comment: _commentController.text,
      );
      if (!mounted) return;
      ToastUtils.showSuccess(context, AppStrings.LAB_TEST_SUBMITTED);
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ToastUtils.showServerError(context, error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _isEditing
        ? AppStrings.LAB_TEST_DETAIL_TITLE
        : AppStrings.LAB_TEST_FORM_TITLE;

    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUND,
        appBar: AppBar(
          backgroundColor: AppColors.SURFACE,
          surfaceTintColor: AppColors.TRANSPARENT,
          elevation: 0,
          titleSpacing: 0,
          leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: AppSizes.ICON_XL,
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
          title: Text(title, style: AppTypography.titleMedium),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.PRIMARY),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.MD16),
                children: [
                  _LotCard(lot: widget.lot, test: widget.test),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _plantsController,
                    label: AppStrings.LAB_TEST_FIELD_NUMBER_OF_PLANTS,
                    hint: AppStrings.LAB_TEST_FIELD_NUMBER_OF_PLANTS_HINT,
                    errorText: _plantsError,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_plantsError != null) {
                        setState(() => _plantsError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _femaleController,
                    label: AppStrings.LAB_TEST_FIELD_FEMALE_COUNT,
                    hint: AppStrings.LAB_TEST_FIELD_FEMALE_COUNT_HINT,
                    errorText: _femaleError,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_femaleError != null) {
                        setState(() => _femaleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _otController,
                    label: AppStrings.LAB_TEST_FIELD_OT_COUNT,
                    hint: AppStrings.LAB_TEST_FIELD_OT_COUNT_HINT,
                    errorText: _otError,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_otError != null) {
                        setState(() => _otError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  AppTextField(
                    controller: _commentController,
                    label: AppStrings.LAB_TEST_FIELD_COMMENT,
                    hint: AppStrings.LAB_TEST_FIELD_COMMENT_HINT,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  _FormulaPreview(
                    impurity: _impurityPreview,
                    growOut: _growOutPreview,
                  ),
                  const SizedBox(height: AppSpacing.MD16),
                  _VerdictButtons(
                    isLoading: _isSaving,
                    onPass: () => _verdict('Pass'),
                    onFail: () => _verdict('Fail'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  final InwardRawMaterial? lot;
  final LabTesting? test;

  const _LotCard({this.lot, this.test});

  @override
  Widget build(BuildContext context) {
    final InwardRawMaterial raw = lot ?? test!.inwardRawMaterial;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.PRIMARY_SURFACE,
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            raw.product.name,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.TEXT_PRIMARY,
            ),
          ),
          const SizedBox(height: AppSpacing.SM8),
          Text(
            raw.party.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.TEXT_SECONDARY,
            ),
          ),
          const SizedBox(height: AppSpacing.SM8),
          Text(
            '${raw.lotNo} · ${raw.quantityKg} ${AppStrings.KG_LABEL}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.TEXT_TERTIARY,
            ),
          ),
        ],
      ),
    );
  }
}

/// The two read-outs the server will store, updated as the counts change.
/// Not editable, and deliberately not what gets sent on submit.
class _FormulaPreview extends StatelessWidget {
  final double? impurity;
  final double? growOut;

  const _FormulaPreview({this.impurity, this.growOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.LAB_TEST_FORMULA_TITLE,
              style: AppTypography.labelStrong),
          const SizedBox(height: AppSpacing.SMD12),
          _FormulaRow(
            label: AppStrings.LAB_TEST_GENETICAL_IMPURITY,
            value: _format(impurity),
          ),
          const SizedBox(height: AppSpacing.SM8),
          _FormulaRow(
            label: AppStrings.LAB_TEST_GROW_OUT_TEST,
            value: _format(growOut),
            isEmphasis: true,
          ),
        ],
      ),
    );
  }

  static String _format(double? value) => value == null ? '--' : '${value}%';
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEmphasis;

  const _FormulaRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          value,
          style: isEmphasis
              ? AppTypography.labelStrong.copyWith(color: AppColors.PRIMARY)
              : AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

class _VerdictButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPass;
  final VoidCallback onFail;

  const _VerdictButtons({
    required this.isLoading,
    required this.onPass,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _VerdictButton(
            label: AppStrings.LAB_TEST_PASS,
            color: AppColors.SUCCESS,
            enabled: !isLoading,
            onTap: onPass,
          ),
        ),
        const SizedBox(width: AppSpacing.SMD12),
        Expanded(
          child: _VerdictButton(
            label: AppStrings.LAB_TEST_FAIL,
            color: AppColors.ERROR,
            enabled: !isLoading,
            onTap: onFail,
          ),
        ),
      ],
    );
  }
}

class _VerdictButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _VerdictButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.SURFACE : AppColors.SURFACE_VARIANT,
      borderRadius: BorderRadius.circular(AppRadius.LG),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: AppSizes.BUTTON_HEIGHT,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? color : AppColors.BORDER),
            borderRadius: BorderRadius.circular(AppRadius.LG),
          ),
          child: Text(
            label,
            style: AppTypography.button.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}