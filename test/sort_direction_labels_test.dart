import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/clients/data/models/client_filter.dart';
import 'package:frontend_erp/features/clients/data/models/clients_query.dart';
import 'package:frontend_erp/features/clients/presentation/widgets/clients_filter_sheet.dart';

/// Every sort the three endpoints actually expose, keyed as the backend sends
/// it. Orders: created_at, price. Clients: created_at, company_name.
/// Catalogue: price, stage, name.
const List<ClientSort> _allSorts = [
  ClientSort(key: 'created_at', label: 'Created'),
  ClientSort(key: 'price', label: 'Price'),
  ClientSort(key: 'company_name', label: 'Company Name'),
  ClientSort(key: 'name', label: 'Name'),
  ClientSort(key: 'stage', label: 'Stage'),
];

Future<void> _openSheet(
  WidgetTester tester, {
  required List<ClientSort> sorts,
  String? selectedSort,
}) async {
  tester.view.physicalSize = const Size(738, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => ClientsFilterSheet.show(
              context,
              filters: const [],
              sorts: sorts,
              query: ClientsQuery(sort: selectedSort),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('sort kind is read off the key', () {
    test('a date field sorts as a date', () {
      expect(const ClientSort(key: 'created_at').kind, SortKind.date);
      expect(const ClientSort(key: 'updated_at').kind, SortKind.date);
      expect(const ClientSort(key: 'verified_at').kind, SortKind.date);
    });

    test('a money or quantity field sorts as a number', () {
      expect(const ClientSort(key: 'price').kind, SortKind.number);
      expect(const ClientSort(key: 'total_amount').kind, SortKind.number);
      expect(const ClientSort(key: 'total_weight').kind, SortKind.number);
      expect(const ClientSort(key: 'item_count').kind, SortKind.number);
    });

    test('a name field sorts as text', () {
      expect(const ClientSort(key: 'name').kind, SortKind.text);
      expect(const ClientSort(key: 'company_name').kind, SortKind.text);
    });

    test('stage reads as text, since its order is a named progression', () {
      // Ascending runs breeder -> certificate; "highest first" would say
      // nothing useful about that.
      expect(const ClientSort(key: 'stage').kind, SortKind.text);
    });

    test('an unknown key falls back to text rather than throwing', () {
      expect(const ClientSort(key: 'something_new').kind, SortKind.text);
      expect(const ClientSort(key: '').kind, SortKind.text);
    });
  });

  group('direction rows are worded for what is being sorted', () {
    testWidgets('a date sort reads newest / oldest', (tester) async {
      await _openSheet(tester, sorts: _allSorts, selectedSort: 'created_at');

      expect(find.text('Newest first'), findsOneWidget);
      expect(find.text('Oldest first'), findsOneWidget);
      expect(find.text('Highest first'), findsNothing);
    });

    testWidgets('a price sort reads highest / lowest', (tester) async {
      await _openSheet(tester, sorts: _allSorts, selectedSort: 'price');

      expect(find.text('Highest first'), findsOneWidget);
      expect(find.text('Lowest first'), findsOneWidget);
      // The bug: a price sorted "newest first" says nothing.
      expect(find.text('Newest first'), findsNothing);
      expect(find.text('Oldest first'), findsNothing);
    });

    testWidgets('a company name sort reads A to Z', (tester) async {
      await _openSheet(tester, sorts: _allSorts, selectedSort: 'company_name');

      expect(find.text('A to Z'), findsOneWidget);
      expect(find.text('Z to A'), findsOneWidget);
      expect(find.text('Newest first'), findsNothing);
    });

    testWidgets('a product name sort reads A to Z', (tester) async {
      await _openSheet(tester, sorts: _allSorts, selectedSort: 'name');

      expect(find.text('A to Z'), findsOneWidget);
      expect(find.text('Z to A'), findsOneWidget);
    });

    testWidgets('no direction rows appear until a sort is picked', (
      tester,
    ) async {
      await _openSheet(tester, sorts: _allSorts);

      expect(find.text('Newest first'), findsNothing);
      expect(find.text('Highest first'), findsNothing);
      expect(find.text('A to Z'), findsNothing);
    });

    testWidgets('switching sorts rewords the directions', (tester) async {
      await _openSheet(tester, sorts: _allSorts, selectedSort: 'created_at');
      expect(find.text('Newest first'), findsOneWidget);

      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();

      expect(find.text('Highest first'), findsOneWidget);
      expect(find.text('Newest first'), findsNothing);
    });
  });
}
