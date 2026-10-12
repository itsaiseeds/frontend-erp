import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/pdf_downloader.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/loaders/dots_loader.dart';
import '../data/lab_tester_repository.dart';
import '../data/models/lab_report_export.dart';
import '../utils/lab_report_generator.dart';

/// Lets a lab tester pick a date range and turn the export into a branded
/// PDF. The two date fields share one row so the range reads as a single
/// control; the report itself is fetched, rendered once and then previewed
/// and saved from the same bytes, exactly as the dispatch challan does.
class LabReportExportScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const LabReportExportScreen({super.key, this.onMenuTap});

  @override
  State<LabReportExportScreen> createState() => _LabReportExportScreenState();
}

class _LabReportExportScreenState extends State<LabReportExportScreen> {
  static const double _doubleTapScale = 2.5;

  final TransformationController _zoom = TransformationController();

  DateTime? _startDate;
  DateTime? _endDate;
  LabReportExport? _report;
  Uint8List? _pdf;
  String? _error;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSharing = false;

  Offset _zoomAnchor = Offset.zero;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// Zooms to where the user tapped, so the detail they aimed at is what
  /// fills the screen -- and back out again on a second tap. A twelve-column
  /// table on a phone needs this more than the challan does.
  void _toggleZoom() {
    final bool isZoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;

    _zoom.value = isZoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
              ..translateByDouble(
                -_zoomAnchor.dx * (_doubleTapScale - 1),
                -_zoomAnchor.dy * (_doubleTapScale - 1),
                0,
                1,
              )
              ..scaleByDouble(
                _doubleTapScale,
                _doubleTapScale,
                _doubleTapScale,
                1,
              ));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initial =
        (isStart ? _startDate : _endDate) ??
        _startDate ??
        _endDate ??
        DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final ThemeData theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.PRIMARY,
              onPrimary: AppColors.TEXT_ON_PRIMARY,
              surface: AppColors.SURFACE,
              onSurface: AppColors.TEXT_PRIMARY,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: AppColors.SURFACE,
              headerBackgroundColor: AppColors.PRIMARY,
              headerForegroundColor: AppColors.TEXT_ON_PRIMARY,
              todayBorder: BorderSide(color: AppColors.PRIMARY),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // A range whose end has fallen behind its start is not a range, so
        // the end is pulled forward rather than left for the user to fix.
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _generate() async {
    final DateTime? from = _startDate;
    final DateTime? to = _endDate;
    if (from == null || to == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _pdf = null;
      _report = null;
    });

    try {
      final LabTesterRepository repository = LabTesterRepository(
        apiClient: context.read<ApiClient>(),
      );
      final LabReportExport report = await repository.fetchLabReportExport(
        startDate: DateFormat('yyyy-MM-dd').format(from),
        endDate: DateFormat('yyyy-MM-dd').format(to),
      );
      // Rendered once here so the preview and the saved file are the same
      // bytes, and saving does not lay the document out a second time.
      final Uint8List pdf = await LabReportGenerator.generate(report);
      if (!mounted) return;

      setState(() {
        _report = report;
        _pdf = pdf;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.LAB_EXPORT_FAILED;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final Uint8List? bytes = _pdf;
    if (bytes == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Writes straight into the Downloads folder on Android 10+; older
      // systems open the share sheet instead (the downloader decides).
      final bool saved = await PdfDownloader.download(bytes, _fileName);
      if (mounted && saved) {
        ToastUtils.showSuccess(context, AppStrings.LAB_EXPORT_DOWNLOADED);
      }
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showError(context, AppStrings.LAB_EXPORT_DOWNLOAD_FAILED);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Share is always the OS share sheet, whatever [_save] did -- a reader who
  /// wants the file handed to someone else (WhatsApp, email) should not have
  /// to care how the download itself landed.
  Future<void> _share() async {
    final Uint8List? bytes = _pdf;
    if (bytes == null || _isSharing) return;

    setState(() => _isSharing = true);

    try {
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showError(context, AppStrings.LAB_EXPORT_SHARE_FAILED);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String get _fileName {
    final LabReportExport? report = _report;
    final String range = report == null
        ? ''
        : '${report.startDate}-to-${report.endDate}';
    return '${AppStrings.LAB_EXPORT_FILE_PREFIX}$range.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUND,
      appBar: AppBar(
        backgroundColor: AppColors.SURFACE,
        surfaceTintColor: AppColors.TRANSPARENT,
        elevation: 0,
        leading: widget.onMenuTap == null
            ? null
            : IconButton(
                onPressed: widget.onMenuTap,
                icon: const Icon(Icons.menu_rounded),
              ),
        title: Text(
          AppStrings.LAB_EXPORT_TITLE,
          style: AppTypography.titleMedium,
        ),
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(child: _buildResult()),
        ],
      ),
      bottomNavigationBar: _pdf == null ? null : _buildSaveBar(),
    );
  }

  /// The range picker and the action that consumes it, pinned above the
  /// result so a new range can be generated without leaving the screen.
  Widget _buildControls() {
    return Container(
      color: AppColors.SURFACE,
      padding: const EdgeInsets.all(AppSpacing.SMD12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: AppStrings.LAB_EXPORT_START_DATE,
                  value: _startDate,
                  placeholder: AppStrings.LAB_EXPORT_PICK_DATE,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.SMD12),
              Expanded(
                child: _DateField(
                  label: AppStrings.LAB_EXPORT_END_DATE,
                  value: _endDate,
                  placeholder: AppStrings.LAB_EXPORT_PICK_DATE,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.SMD12),
          PrimaryButton(
            label: AppStrings.LAB_EXPORT_GENERATE,
            icon: Icons.picture_as_pdf_outlined,
            onPressed: _startDate == null || _endDate == null || _isLoading
                ? null
                : _generate,
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_isLoading) {
      return const Center(child: DotsLoader());
    }

    if (_error != null) {
      return _ExportMessage(
        icon: Icons.error_outline_rounded,
        title: AppStrings.LAB_EXPORT_FAILED,
        message: _error!,
        onRetry: _generate,
      );
    }

    final Uint8List? pdf = _pdf;
    if (pdf == null) {
      return const _ExportMessage(
        icon: Icons.date_range_outlined,
        title: AppStrings.LAB_EXPORT_EMPTY_TITLE,
        message: AppStrings.LAB_EXPORT_EMPTY_BODY,
      );
    }

    // Pinch and double-tap to zoom: the report's columns are small print on
    // a phone, and PdfPreview does not scale on its own.
    return InteractiveViewer(
      transformationController: _zoom,
      minScale: 1,
      maxScale: 4,
      child: GestureDetector(
        onDoubleTapDown: (details) => _zoomAnchor = details.localPosition,
        onDoubleTap: _toggleZoom,
        child: PdfPreview(
          build: (format) => pdf,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          useActions: false,
          loadingWidget: const Center(child: DotsLoader()),
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.SMD12),
        child: Row(
          children: [
            Expanded(
              child: _OutlinedActionButton(
                label: AppStrings.LAB_EXPORT_SHARE,
                icon: Icons.share_outlined,
                isLoading: _isSharing,
                onPressed: _isSharing || _isSaving ? null : _share,
              ),
            ),
            const SizedBox(width: AppSpacing.SMD12),
            Expanded(
              child: PrimaryButton(
                label: AppStrings.LAB_EXPORT_DOWNLOAD,
                icon: Icons.download_outlined,
                isLoading: _isSaving,
                onPressed: _isSaving || _isSharing ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The outlined half of the save bar -- [PrimaryButton]'s filled style would
/// make Share and Download compete for the same visual weight, when only one
/// of them (Download) is the default action.
class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _OutlinedActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    return OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.PRIMARY,
        disabledForegroundColor: AppColors.TEXT_DISABLED,
        side: BorderSide(
          color: isDisabled ? AppColors.BORDER : AppColors.PRIMARY,
        ),
        minimumSize: const Size(
          AppSizes.BUTTON_MIN_WIDTH,
          AppSizes.BUTTON_HEIGHT,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.LG24,
          vertical: AppSpacing.SMD12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.CHIP),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: AppSpacing.MD16,
              width: AppSpacing.MD16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSizes.ICON_SM),
                const SizedBox(width: AppSpacing.SM8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(
                      color: isDisabled
                          ? AppColors.TEXT_DISABLED
                          : AppColors.PRIMARY,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One tappable date field: label above, calendar icon and value inside a
/// bordered surface. The two of these share a row to read as one range.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final String placeholder;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        const SizedBox(height: AppSpacing.XS4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.MD),
          child: Container(
            width: double.infinity,
            height: AppSizes.INPUT_HEIGHT,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.SM10),
            decoration: BoxDecoration(
              color: AppColors.SURFACE,
              border: Border.all(color: AppColors.BORDER),
              borderRadius: BorderRadius.circular(AppRadius.MD),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.ICON_SM,
                  color: hasValue ? AppColors.PRIMARY : AppColors.TEXT_DISABLED,
                ),
                const SizedBox(width: AppSpacing.SM8),
                Expanded(
                  child: Text(
                    hasValue ? DateFormat.yMMMd().format(value!) : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasValue
                          ? AppColors.TEXT_PRIMARY
                          : AppColors.TEXT_DISABLED,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.XS4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.ICON_MD,
                  color: AppColors.TEXT_DISABLED,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _ExportMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.LG24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.ICON_XXL, color: AppColors.TEXT_DISABLED),
            const SizedBox(height: AppSpacing.SMD12),
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.XS4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.SMD12),
              PrimaryButton(label: AppStrings.RETRY, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
