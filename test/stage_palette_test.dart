import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/theme/app_colors.dart';
import 'package:frontend_erp/features/products/presentation/widgets/stage_palette.dart';

void main() {
  test('the four seeded stages are all visually distinct', () {
    // Breeder(1), Foundation(2), Research(3), Certificate(4).
    final foregrounds = {
      for (int i = 1; i <= 4; i++) StagePalette.forSequence(i).foreground,
    };
    expect(foregrounds.length, 4, reason: 'stages must be distinguishable');
  });

  test('the ramp runs red at the bottom through to green at the top', () {
    expect(StagePalette.forSequence(0).foreground, AppColors.ERROR);
    expect(StagePalette.forSequence(1).foreground, AppColors.ERROR);
    expect(StagePalette.forSequence(4).foreground, AppColors.SUCCESS);
  });

  test('the same sequence always resolves to the same colour', () {
    expect(
      StagePalette.forSequence(2).foreground,
      StagePalette.forSequence(2).foreground,
    );
  });

  test('background is the light pair of the foreground', () {
    expect(StagePalette.forSequence(3).foreground, AppColors.INFO);
    expect(StagePalette.forSequence(3).background, AppColors.INFO_LIGHT);
  });

  test('a sequence outside the seeded range falls back to neutral', () {
    expect(StagePalette.forSequence(-1).foreground, AppColors.TEXT_SECONDARY);
    expect(StagePalette.forSequence(9).background, AppColors.SURFACE_VARIANT);
  });
}
