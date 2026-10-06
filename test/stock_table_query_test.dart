import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_erp/features/godown/data/models/stock_table_query.dart';

void main() {
  group('search', () {
    test('a blank term matches everything', () {
      expect(stockRowMatches(query: '   ', title: 'Basmati Rice'), isTrue);
    });

    test('the product name matches case-insensitively', () {
      expect(stockRowMatches(query: 'rice', title: 'Basmati Rice'), isTrue);
      expect(stockRowMatches(query: 'RICE', title: 'Basmati Rice'), isTrue);
    });

    test('the packaging detail is searchable too', () {
      expect(
        stockRowMatches(
          query: '30 kg',
          title: 'Toor Dal',
          subtitle: '30 KG x 10',
        ),
        isTrue,
      );
    });

    test('a non-matching term rejects the row', () {
      expect(stockRowMatches(query: 'zzzz', title: 'Basmati Rice'), isFalse);
    });
  });

  group('count filter', () {
    test('all matches regardless of position', () {
      for (final bool hasPosition in [true, false]) {
        expect(StockCountFilter.all.matches(hasPosition: hasPosition), isTrue);
      }
    });

    test('counted requires a position', () {
      expect(StockCountFilter.counted.matches(hasPosition: true), isTrue);
      expect(StockCountFilter.counted.matches(hasPosition: false), isFalse);
    });

    test('not counted requires the absence of one', () {
      expect(StockCountFilter.notCounted.matches(hasPosition: false), isTrue);
      expect(StockCountFilter.notCounted.matches(hasPosition: true), isFalse);
    });
  });

  group('sorting', () {
    test('name ascending is case-insensitive', () {
      final int result = compareStockRows(
        StockSort.nameAsc,
        title: 'basmati rice',
        available: 10,
        otherTitle: 'Toor Dal',
        otherAvailable: 20,
      );
      expect(result, lessThan(0));
    });

    test('available descending puts the larger pool first', () {
      final int result = compareStockRows(
        StockSort.availableDesc,
        title: 'B',
        available: 5,
        otherTitle: 'A',
        otherAvailable: 40,
      );
      expect(result, greaterThan(0));
    });

    test('available ascending puts the smaller pool first', () {
      final int result = compareStockRows(
        StockSort.availableAsc,
        title: 'A',
        available: 0,
        otherTitle: 'B',
        otherAvailable: 40,
      );
      expect(result, lessThan(0));
    });

    test('an uncounted row sinks to the bottom in either direction', () {
      // A null available figure is "no number", not the smallest number, so it
      // must not jump ahead just because the sort is ascending.
      expect(
        compareStockRows(
          StockSort.availableAsc,
          title: 'Uncounted',
          available: null,
          otherTitle: 'Zero',
          otherAvailable: 0,
        ),
        greaterThan(0),
      );
      expect(
        compareStockRows(
          StockSort.availableDesc,
          title: 'Uncounted',
          available: null,
          otherTitle: 'Zero',
          otherAvailable: 0,
        ),
        greaterThan(0),
      );
    });

    test('two uncounted rows compare equal', () {
      expect(
        compareStockRows(
          StockSort.availableAsc,
          title: 'A',
          available: null,
          otherTitle: 'B',
          otherAvailable: null,
        ),
        0,
      );
    });
  });

  group('activeCount', () {
    test('the untouched default reports nothing active', () {
      expect(const StockTableQuery().activeCount, 0);
    });

    test('a non-default sort counts once', () {
      expect(
        const StockTableQuery(sort: StockSort.availableDesc).activeCount,
        1,
      );
    });

    test('filter and sort together count twice', () {
      expect(
        const StockTableQuery(
          filter: StockCountFilter.counted,
          sort: StockSort.availableAsc,
        ).activeCount,
        2,
      );
    });

    test('a search term does not count as an active filter', () {
      // The search box is visible on the toolbar, so the badge is reserved for
      // controls whose effect is otherwise invisible.
      expect(const StockTableQuery(search: 'rice').activeCount, 0);
    });
  });

  test('copyWith changes only the named field', () {
    const StockTableQuery base = StockTableQuery(
      search: 'rice',
      filter: StockCountFilter.counted,
      sort: StockSort.availableAsc,
    );

    final StockTableQuery next = base.copyWith(sort: StockSort.nameAsc);

    expect(next.search, 'rice');
    expect(next.filter, StockCountFilter.counted);
    expect(next.sort, StockSort.nameAsc);
  });
}
