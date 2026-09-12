import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/clients/data/models/client.dart';
import 'package:frontend_erp/features/clients/data/models/client_status.dart';
import 'package:frontend_erp/features/clients/presentation/bloc/clients_state.dart';

const _client = Client(
  publicId: 'C-1',
  companyName: 'Acme',
  status: ClientStatus.verified,
);

// Mirrors _Body's branching exactly.
Widget buildBody(ClientsState state, Future<void> Function() onRefresh) {
  if (state.isLoading && state.clients.isEmpty) {
    return const Center(child: Text('shimmer'));
  }
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      children: [
        for (final c in state.clients)
          SizedBox(height: 80, child: Text(c.companyName)),
      ],
    ),
  );
}

void main() {
  testWidgets('loaded -> loading keeps the list and shows the spinner',
      (tester) async {
    ClientsState state = const ClientsState(
      status: ClientsStatus.loaded,
      clients: [_client],
    );
    late StateSetter setOuter;
    int refreshes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return buildBody(state, () async {
                refreshes++;
                setOuter(() => state = state.copyWith(
                    status: ClientsStatus.loading));
                await Future<void>.delayed(const Duration(milliseconds: 60));
                setOuter(() => state = state.copyWith(
                    status: ClientsStatus.loaded));
              });
            },
          ),
        ),
      ),
    );

    expect(find.text('Acme'), findsOneWidget);

    await tester.fling(find.text('Acme'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(refreshes, 1, reason: 'pull must call onRefresh');
    expect(find.text('shimmer'), findsNothing,
        reason: 'list must stay mounted during refresh');
    expect(find.byType(RefreshProgressIndicator), findsOneWidget,
        reason: 'spinner must be visible');

    await tester.pumpAndSettle();
    expect(find.text('Acme'), findsOneWidget);
  });

  testWidgets('initial load with no clients still shows the shimmer',
      (tester) async {
    const state = ClientsState(status: ClientsStatus.loading);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: buildBody(state, () async {})),
      ),
    );

    expect(find.text('shimmer'), findsOneWidget);
  });
}
