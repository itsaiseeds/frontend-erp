import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/loaders/dots_loader.dart';
import '../data/challan_repository.dart';
import '../data/models/challan.dart';
import '../utils/challan_generator.dart';

/// Shows the dispatch challan for one order, and saves it as a PDF.
///
/// The document is the same one the admin portal prints -- the generator is
/// shared -- so a challan looks identical wherever it came from.
class ChallanScreen extends StatefulWidget {
  final String orderPublicId;

  const ChallanScreen({super.key, required this.orderPublicId});

  static Future<void> open(
    BuildContext context, {
    required String orderPublicId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChallanScreen(orderPublicId: orderPublicId),
      ),
    );
  }

  @override
  State<ChallanScreen> createState() => _ChallanScreenState();
}

class _ChallanScreenState extends State<ChallanScreen> {
  final TransformationController _zoom = TransformationController();

  static const double _doubleTapScale = 2.5;

  Offset _zoomAnchor = Offset.zero;
  Challan? _challan;
  Uint8List? _pdf;
  String? _error;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  /// Zooms to where the user tapped, so the detail they aimed at is what
  /// fills the screen -- and back out again on a second tap.
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ChallanRepository repository = ChallanRepository(
        apiClient: context.read<ApiClient>(),
      );
      final Challan challan = await repository.fetchChallan(
        widget.orderPublicId,
      );
      // Rendered once here so the preview and the saved file are the same
      // bytes, and saving does not lay the document out a second time.
      final Uint8List pdf = await ChallanGenerator.generate(challan);
      if (!mounted) return;

      setState(() {
        _challan = challan;
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
        _error = AppStrings.CHALLAN_LOAD_FAILED;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final Uint8List? bytes = _pdf;
    if (bytes == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showError(context, AppStrings.CHALLAN_DOWNLOAD_FAILED);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _fileName =>
      '${AppStrings.CHALLAN_FILE_PREFIX}'
      '${_challan?.fileReference ?? widget.orderPublicId}.pdf';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUND,
      appBar: AppBar(
        backgroundColor: AppColors.SURFACE,
        surfaceTintColor: AppColors.TRANSPARENT,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: AppSizes.ICON_XL,
            color: AppColors.TEXT_PRIMARY,
          ),
        ),
        // The back chevron is already inset, so the default gap leaves the
        // title drifting away from it.
        titleSpacing: 0,
        leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
        title: Text(
          AppStrings.CHALLAN_TITLE,
          style: AppTypography.titleMedium,
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _pdf == null ? null : _buildSaveBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: DotsLoader());
    }

    if (_error != null) {
      return _ChallanMessage(
        icon: Icons.error_outline_rounded,
        message: _error!,
        onRetry: _load,
      );
    }

    // Pinch and double-tap to zoom: a challan's lot numbers and totals are
    // small print on a phone, and PdfPreview does not scale on its own.
    return InteractiveViewer(
      transformationController: _zoom,
      minScale: 1,
      maxScale: 4,
      child: GestureDetector(
        onDoubleTapDown: (details) => _zoomAnchor = details.localPosition,
        onDoubleTap: _toggleZoom,
        child: PdfPreview(
          build: (format) => _pdf!,
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
        child: PrimaryButton(
          label: AppStrings.CHALLAN_DOWNLOAD,
          icon: Icons.download_outlined,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _save,
        ),
      ),
    );
  }
}

class _ChallanMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _ChallanMessage({
    required this.icon,
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.TEXT_SECONDARY,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.SMD12),
              PrimaryButton(
                label: AppStrings.RETRY,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
