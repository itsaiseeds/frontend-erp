import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/clients/presentation/widgets/client_card_shimmer.dart';

Future<void> _expectPullWorks(WidgetTester tester, Widget child,
    {required String label}) async {
  int refreshes = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            refreshes++;
            await Future<void>.delayed(const Duration(milliseconds: 40));
          },
          child: child,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));

  await tester.fling(find.byType(RefreshIndicator), const Offset(0, 400), 1200);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(refreshes, 1, reason: '$label must accept the pull gesture');
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('shimmer accepts pull-to-refresh', (tester) async {
    await _expectPullWorks(
      tester,
      const ClientCardShimmer(isScrollable: true),
      label: 'shimmer',
    );
  });

  testWidgets('populated list accepts pull-to-refresh', (tester) async {
    await _expectPullWorks(
      tester,
      ListView(children: const [SizedBox(height: 80, child: Text('row'))]),
      label: 'list',
    );
  });

  testWidgets('empty message accepts pull-to-refresh', (tester) async {
    await _expectPullWorks(
      tester,
      LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: const Center(child: Text('empty')),
          ),
        ),
      ),
      label: 'empty state',
    );
  });
}
