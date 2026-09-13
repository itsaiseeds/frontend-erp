import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_url_resolver.dart';

/// Full-screen product shot: pinch or double-tap to zoom, drag to pan.
class ImageViewerSheet extends StatefulWidget {
  final String imageUrl;

  /// Rendered under the image, so the buy action stays reachable while
  /// inspecting the packet.
  final Widget? footer;

  const ImageViewerSheet({super.key, required this.imageUrl, this.footer});

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    Widget? footer,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ImageViewerSheet(imageUrl: imageUrl, footer: footer),
      ),
    );
  }

  @override
  State<ImageViewerSheet> createState() => _ImageViewerSheetState();
}

class _ImageViewerSheetState extends State<ImageViewerSheet>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 1;
  static const double _doubleTapScale = 2;
  static const double _maxScale = 4;
  static const Duration _duration = Duration(milliseconds: 220);

  final TransformationController _controller = TransformationController();

  // Built in initState rather than lazily: a `late final` field would be
  // created *inside* dispose() when the viewer is closed without zooming,
  // and constructing a ticker there looks up a dead element's ancestor.
  late final AnimationController _animation;

  Animation<Matrix4>? _zoom;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: _duration);
  }

  @override
  void dispose() {
    _zoom?.removeListener(_applyZoom);
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applyZoom() {
    final Animation<Matrix4>? zoom = _zoom;
    if (zoom == null) return;
    setState(() => _controller.value = zoom.value);
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  void _animateTo(Matrix4 target) {
    _zoom?.removeListener(_applyZoom);
    _zoom = Matrix4Tween(begin: _controller.value, end: target).animate(
      CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic),
    )..addListener(_applyZoom);

    _animation.forward(from: 0);
  }

  /// Double-tap zooms to 200% centred on the tapped point, and back out.
  void _onDoubleTapAt(Offset position) {
    if (_scale > _minScale) {
      _animateTo(Matrix4.identity());
      return;
    }

    final Matrix4 target = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (_doubleTapScale - 1),
        -position.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, _doubleTapScale, 1);

    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final String url = ImageUrlResolver.resolve(widget.imageUrl);

    return Scaffold(
      backgroundColor: AppColors.BACKGROUND,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: GestureDetector(
                onDoubleTapDown: (details) =>
                    _onDoubleTapAt(details.localPosition),
                onDoubleTap: () {},
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  onInteractionEnd: (_) => setState(() {}),
                  child: Container(
                    color: AppColors.SURFACE,
                    alignment: Alignment.center,
                    child: url.isEmpty
                        ? const _Fallback()
                        : Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) =>
                                const _Fallback(),
                          ),
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
      bottomNavigationBar: widget.footer,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: AppSizes.VIEWER_BUTTON,
            height: AppSizes.VIEWER_BUTTON,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.TEXT_PRIMARY,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: AppSizes.ICON_LG,
              color: AppColors.TEXT_ON_PRIMARY,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      child: Center(
        child: Text(
          _scale > _minScale
              ? '${(_scale * 100).round()}%'
              : AppStrings.IMAGE_ZOOM_HINT,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.TEXT_TERTIARY,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.inventory_2_outlined,
      size: AppSizes.ICON_XXL,
      color: AppColors.TEXT_DISABLED,
    );
  }
}
