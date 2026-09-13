import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/widgets/inputs/geo_picker_field.dart';

/// Drives the picker the way a desktop browser does: a mouse press, which
/// moves focus away from the field before the tap on the option resolves.
Future<void> _clickWithMouse(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.down(tester.getCenter(target));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<List<String>> _pumpPicker(
  WidgetTester tester, {
  List<String> items = const ['Alpha', 'Beta', 'Gamma'],
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final List<String> picked = [];
  String? value;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) => GeoPickerField<String>(
              label: 'Transport agency',
              hint: 'Select dispatch',
              value: value,
              items: items,
              itemLabel: (item) => item,
              isSame: (a, b) => a == b,
              onSelected: (item) {
                picked.add(item);
                setState(() => value = item);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  testWidgets('the panel opens when the field is tapped', (tester) async {
    await _pumpPicker(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('an option can be picked with a mouse click', (tester) async {
    final List<String> picked = await _pumpPicker(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // On web the press moves focus off the field first; if that tears the
    // overlay down, the option never receives the tap.
    await _clickWithMouse(tester, find.text('Beta'));

    expect(picked, ['Beta']);
  });

  testWidgets('an option can be picked by touch', (tester) async {
    final List<String> picked = await _pumpPicker(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gamma'));
    await tester.pumpAndSettle();

    expect(picked, ['Gamma']);
  });

  testWidgets('the panel sits under the field, not at the screen origin', (
    tester,
  ) async {
    await _pumpPicker(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final Rect field = tester.getRect(find.byType(TextField));
    final Rect option = tester.getRect(find.text('Alpha'));

    // An unpositioned overlay lands at the top-left and the visible panel no
    // longer matches where taps are routed.
    expect(option.top, greaterThan(field.top));
    expect(option.left, greaterThanOrEqualTo(field.left));
  });

  testWidgets('picking closes the panel', (tester) async {
    await _pumpPicker(tester);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await _clickWithMouse(tester, find.text('Alpha'));

    expect(find.text('Beta'), findsNothing);
  });
}
