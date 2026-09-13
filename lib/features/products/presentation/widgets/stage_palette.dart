import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StageColors {
  final Color foreground;
  final Color background;

  const StageColors({required this.foreground, required this.background});
}

/// Stage badge colours keyed by the backend's ``sequence``.
///
/// The stage table is a fixed, seeded vocabulary ordered by ``sequence``, so
/// each rank keeps one colour across the app. Rule B.9 allows semantic hues,
/// which is what these are -- a classification, not decoration.
class StagePalette {
  StagePalette._();

  /// Indexed by sequence: 0 is the weakest grade and the top of the range the
  /// strongest, so the ramp runs red -> amber -> blue -> green. The seeded
  /// stages use 1..4, and 0 is kept as a defined red rather than a fallback.
  static const List<StageColors> _bySequence = [
    StageColors(foreground: AppColors.ERROR, background: AppColors.ERROR_LIGHT),
    StageColors(foreground: AppColors.ERROR, background: AppColors.ERROR_LIGHT),
    StageColors(
      foreground: AppColors.WARNING,
      background: AppColors.WARNING_LIGHT,
    ),
    StageColors(foreground: AppColors.INFO, background: AppColors.INFO_LIGHT),
    StageColors(
      foreground: AppColors.SUCCESS,
      background: AppColors.SUCCESS_LIGHT,
    ),
  ];

  static const StageColors _fallback = StageColors(
    foreground: AppColors.TEXT_SECONDARY,
    background: AppColors.SURFACE_VARIANT,
  );

  /// Sequence runs 0..4 in the seed data; anything outside that falls back to
  /// a neutral chip rather than guessing a hue.
  static StageColors forSequence(int sequence) {
    if (sequence < 0 || sequence >= _bySequence.length) return _fallback;
    return _bySequence[sequence];
  }
}
