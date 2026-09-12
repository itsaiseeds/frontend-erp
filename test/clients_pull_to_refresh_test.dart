import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dragging a short list down triggers onRefresh', (tester) async {
    int refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => refreshCount++,
            child: ListView(
              children: const [
                SizedBox(height: 80, child: Text('one')),
                SizedBox(height: 80, child: Text('two')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.fling(find.text('one'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });

  testWidgets('an empty message still refreshes when wrapped in a scrollable', (
    tester,
  ) async {
    int refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => refreshCount++,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: const Center(child: Text('No clients')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.fling(find.text('No clients'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });
}
