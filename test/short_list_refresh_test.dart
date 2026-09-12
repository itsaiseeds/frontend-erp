import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ONE card on a tall screen still accepts the pull',
      (tester) async {
    tester.view.physicalSize = const Size(374, 724);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    int refreshes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 160), // header + switcher + search
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    refreshes++;
                    await Future<void>.delayed(
                        const Duration(milliseconds: 40));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: 2, // 1 client + footer, as the real screen does
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => index == 1
                        ? const SizedBox(height: 24)
                        : const SizedBox(height: 120, child: Text('Test')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.fling(find.text('Test'), const Offset(0, 400), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: 'spinner must appear for a single-card list');
    expect(refreshes, 1);

    await tester.pump(const Duration(seconds: 1));
  });
}
