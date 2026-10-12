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
import '../../../core/utils/pdf_downloader.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/loaders/dots_loader.dart';
import '../../orders/data/models/order.dart';
import '../../orders/data/orders_repository.dart';
import '../data/models/return_order.dart';
import '../utils/return_order_slip_generator.dart';

/// Shows the return order slip for one accepted return, and saves it as a
/// PDF -- the sales-person equivalent of the admin portal's slip preview.
///
/// The slip needs the parent order's own line prices to compute a net sale
/// per returned item, which the return order payload alone does not carry.
/// There is no single-order detail endpoint on this app, so the order is
/// fetched the same way a notification tap resolves one: by filtering the
/// order list down to its public id.
class ReturnOrderSlipScreen extends StatefulWidget {
  final ReturnOrder returnOrder;

  const ReturnOrderSlipScreen({super.key, required this.returnOrder});

  static Future<void> open(BuildContext context, ReturnOrder returnOrder) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReturnOrderSlipScreen(returnOrder: returnOrder),
      ),
    );
  }

  @override
  State<ReturnOrderSlipScreen> createState() => _ReturnOrderSlipScreenState();
}

class _ReturnOrderSlipScreenState extends State<ReturnOrderSlipScreen> {
  static const double _doubleTapScale = 2.5;

  final TransformationController _zoom = TransformationController();

  Offset _zoomAnchor = Offset.zero;
  Uint8List? _pdf;
  String? _error;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSharing = false;

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
      final OrdersRepository repository = OrdersRepository(
        apiClient: context.read<ApiClient>(),
      );
      final Order? order = await repository.fetchOrderByPublicId(
        widget.returnOrder.order.publicId,
      );
      if (order == null) {
        throw const ApiException(message: AppStrings.RETURN_SLIP_LOAD_FAILED);
      }

      // Rendered once here so the preview and the saved file are the same
      // bytes, and saving does not lay the document out a second time.
      final Uint8List pdf = await ReturnOrderSlipGenerator.generate(
        returnOrder: widget.returnOrder,
        order: order,
      );
      if (!mounted) return;

      setState(() {
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
        _error = AppStrings.RETURN_SLIP_LOAD_FAILED;
        _isLoading = false;
      });
    }
  }

  String get _fileName =>
      '${AppStrings.RETURN_SLIP_FILE_PREFIX}${widget.returnOrder.publicId}.pdf';

  Future<void> _save() async {
    final Uint8List? bytes = _pdf;
    if (bytes == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final bool saved = await PdfDownloader.download(bytes, _fileName);
      if (mounted && saved) {
        ToastUtils.showSuccess(context, AppStrings.RETURN_SLIP_DOWNLOADED);
      }
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showError(context, AppStrings.RETURN_SLIP_DOWNLOAD_FAILED);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _share() async {
    final Uint8List? bytes = _pdf;
    if (bytes == null || _isSharing) return;

    setState(() => _isSharing = true);

    try {
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
    } catch (_) {
      if (!mounted) return;
      ToastUtils.showError(context, AppStrings.RETURN_SLIP_SHARE_FAILED);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

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
        titleSpacing: 0,
        leadingWidth: AppSizes.APP_BAR_LEADING_WIDTH,
        title: Text(
          AppStrings.RETURN_SLIP_TITLE,
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
      return _SlipMessage(
        icon: Icons.error_outline_rounded,
        message: _error!,
        onRetry: _load,
      );
    }

    // Pinch and double-tap to zoom: a slip's prices and totals are small
    // print on a phone, and PdfPreview does not scale on its own.
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
        child: Row(
          children: [
            Expanded(
              child: _OutlinedActionButton(
                label: AppStrings.RETURN_SLIP_SHARE,
                icon: Icons.share_outlined,
                isLoading: _isSharing,
                onPressed: _isSharing || _isSaving ? null : _share,
              ),
            ),
            const SizedBox(width: AppSpacing.SMD12),
            Expanded(
              child: PrimaryButton(
                label: AppStrings.RETURN_SLIP_DOWNLOAD,
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

class _SlipMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _SlipMessage({required this.icon, required this.message, this.onRetry});

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
              PrimaryButton(label: AppStrings.RETRY, onPressed: onRetry),
            ],
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
