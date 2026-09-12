import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class DotsLoader extends StatefulWidget {
  final Color color;
  final double dotSize;

  const DotsLoader({
    super.key,
    this.color = AppColors.PRIMARY,
    this.dotSize = AppSpacing.SM8,
  });

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 3;
  static const Duration _cycle = Duration(milliseconds: 900);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_dotCount, (index) {
            final double phase =
                (_controller.value - (index / _dotCount)) % 1.0;
            final double opacity =
                0.35 + (0.65 * (1.0 - (phase - 0.5).abs() * 2));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.XXS2),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
