import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _body({required bool isLoading, required bool hasClients,
    required Future<void> Function() onRefresh}) {
  if (isLoading && !hasClients) {
    return const Center(child: Text('shimmer'));
  }
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      children: const [SizedBox(height: 80, child: Text('client row'))],
    ),
  );
}

void main() {
  testWidgets('indicator survives the loading emit during refresh',
      (tester) async {
    bool isLoading = false;
    int refreshCount = 0;
    late StateSetter setOuter;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return _body(
                isLoading: isLoading,
                hasClients: true,
                onRefresh: () async {
                  refreshCount++;
                  setOuter(() => isLoading = true);
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  setOuter(() => isLoading = false);
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.fling(find.text('client row'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: 'spinner must stay mounted while loading');

    await tester.pumpAndSettle();
    expect(refreshCount, 1);
  });

  testWidgets('old behaviour unmounts the indicator mid-refresh',
      (tester) async {
    bool isLoading = false;
    late StateSetter setOuter;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              // Old code: shimmer whenever loading, regardless of cached rows.
              if (isLoading) return const Center(child: Text('shimmer'));
              return RefreshIndicator(
                onRefresh: () async {
                  setOuter(() => isLoading = true);
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                },
                child: ListView(
                  children: const [
                    SizedBox(height: 80, child: Text('client row')),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.fling(find.text('client row'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('shimmer'), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsNothing,
        reason: 'this is the bug: the spinner is torn down');
    await tester.pumpAndSettle();
  });
}
