import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _pullCount(WidgetTester tester, {ScrollPhysics? physics}) async {
  tester.view.physicalSize = const Size(374, 724);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  int refreshes = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            refreshes++;
            await Future<void>.delayed(const Duration(milliseconds: 40));
          },
          child: ListView.separated(
            physics: physics,
            itemCount: 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                const SizedBox(height: 120, child: Text('only client')),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.fling(find.text('only client'), const Offset(0, 400), 1200);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 1));

  return refreshes;
}

void main() {
  testWidgets('single item WITH always-scrollable can refresh',
      (tester) async {
    expect(
      await _pullCount(tester, physics: const AlwaysScrollableScrollPhysics()),
      1,
      reason: 'one client must still accept pull-to-refresh',
    );
  });
}
