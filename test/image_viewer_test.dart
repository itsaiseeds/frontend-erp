import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/config/app_config_keys.dart';
import 'package:frontend_erp/features/products/presentation/widgets/image_viewer_sheet.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: ImageViewerSheet(imageUrl: '/media/products/x.jpg'),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: AppConfigKeys.ENV_FILE_DEV);
  });

  testWidgets('opens unzoomed with a hint instead of a percentage',
      (tester) async {
    await _pump(tester);

    expect(find.text('Double tap or pinch to zoom'), findsOneWidget);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('double tap zooms to 200%', (tester) async {
    await _pump(tester);

    final Offset centre = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(centre);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(centre);
    await tester.pumpAndSettle();

    expect(find.text('200%'), findsOneWidget);
  });

  testWidgets('double tap again returns to 100%', (tester) async {
    await _pump(tester);

    final Offset centre = tester.getCenter(find.byType(InteractiveViewer));

    await tester.tapAt(centre);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(centre);
    await tester.pumpAndSettle();
    expect(find.text('200%'), findsOneWidget);

    await tester.tapAt(centre);
    await tester.pump(kDoubleTapMinTime);
    await tester.tapAt(centre);
    await tester.pumpAndSettle();
    expect(find.text('Double tap or pinch to zoom'), findsOneWidget);
  });

  testWidgets('is pinch and pan capable', (tester) async {
    await _pump(tester);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.maxScale, greaterThanOrEqualTo(2));
  });
}
