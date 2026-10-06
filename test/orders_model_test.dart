import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/clients/data/models/client_filter.dart';
import 'package:frontend_erp/features/orders/data/models/order.dart';
import 'package:frontend_erp/features/orders/data/models/order_status.dart';
import 'package:frontend_erp/features/orders/data/models/paginated_orders.dart';

const String _page = '''
{
  "total_count": 2,
  "total_pages": 1,
  "next_page_number": null,
  "previous_page_number": null,
  "results": [
    {
      "public_id": "O-ABC123",
      "created_at": "2026-09-13T17:25:49.434Z",
      "status": "DISPATCHED",
      "client": {"public_id": "C-1", "company_name": "Gurukrupa"},
      "delivery_address": "Plot 4, Ring Road, Rajkot",
      "city": {"id": 7, "name": "Rajkot"},
      "expected_delivery_date": "2026-09-20",
      "dispatch_mode": "AGENCY",
      "total_amount": "35000.00",
      "total_packets": 120,
      "item_count": 3,
      "packagings": [
        {
          "public_id": "PP-1",
          "negotiated_selling_price": "2400.00",
          "product": {
            "public_id": "P-1",
            "name": "SAI-30",
            "image_url": "/media/products/sai30.jpg"
          },
          "packet_weight": "2.00",
          "packets": 40,
          "total_weight": "80.00",
          "selling_price": "2500.00",
          "quantity": 2
        },
        {
          "public_id": "PP-2",
          "negotiated_selling_price": "1200.00",
          "product": {
            "public_id": "P-1",
            "name": "SAI-30",
            "image_url": "/media/products/sai30.jpg"
          },
          "packet_weight": "1.00",
          "packets": 30,
          "total_weight": "30.00",
          "selling_price": "1200.00",
          "quantity": 1
        }
      ],
      "verified": true,
      "verified_by": "Priya Admin",
      "verified_at": "2026-09-13T18:12:03.714Z"
    }
  ],
  "available_filters": [
    {
      "filter": "city_id",
      "label": "City",
      "kind": "select",
      "description": "City ids.",
      "params": [],
      "options": [{"value": 7, "label": "Rajkot"}]
    }
  ],
  "available_sorts": [
    {"sort": "created_at", "label": "Created", "description": "Newest first."}
  ]
}
''';

Order _firstOrder() {
  final Map<String, dynamic> json = Map<String, dynamic>.from(
    jsonDecode(_page) as Map,
  );
  return PaginatedOrders.fromJson(json).results.single;
}

void main() {
  group('order parsing', () {
    test('reads the card fields off the list payload', () {
      final Order order = _firstOrder();

      expect(order.publicId, 'O-ABC123');
      expect(order.client.companyName, 'Gurukrupa');
      expect(order.cityName, 'Rajkot');
      expect(order.totalPackets, 120);
      expect(order.itemCount, 3);
      expect(order.packagings, hasLength(2));
      expect(order.packagings.first.quantity, 2);
    });

    test('total_amount arrives as a string and becomes a number', () {
      final Order order = _firstOrder();

      // A string here would format as a literal, not Indian-grouped rupees.
      expect(order.totalAmount, isA<num>());
      expect(order.totalAmount, 35000);
    });

    test('dates parse into DateTime, not raw strings', () {
      final Order order = _firstOrder();

      expect(order.createdAt, isNotNull);
      expect(order.expectedDeliveryDate!.year, 2026);
      expect(order.expectedDeliveryDate!.month, 9);
      expect(order.expectedDeliveryDate!.day, 20);
    });

    test('an unparseable date is null rather than throwing', () {
      final Order order = Order.fromJson(const {
        'public_id': 'O-1',
        'created_at': '',
        'expected_delivery_date': 'not a date',
      });

      expect(order.createdAt, isNull);
      expect(order.expectedDeliveryDate, isNull);
    });

    test('a packaging line carries the bag, product and picture', () {
      final OrderPackaging line = _firstOrder().packagings.first;

      expect(line.publicId, 'PP-1');
      expect(line.productPublicId, 'P-1');
      expect(line.productName, 'SAI-30');
      expect(line.imageUrl, '/media/products/sai30.jpg');
      expect(line.packets, 40);
      expect(line.quantity, 2);
    });

    test('the decimal-string weights and prices become numbers', () {
      final OrderPackaging line = _firstOrder().packagings.first;

      expect(line.packetWeight, 2);
      expect(line.totalWeight, 80);
      expect(line.sellingPrice, 2500);
      expect(line.negotiatedSellingPrice, 2400);
    });

    test('a line total uses the agreed price, not the list price', () {
      final OrderPackaging line = _firstOrder().packagings.first;

      // 2400 agreed x 2 bags. The 2500 list price would give 5000.
      expect(line.lineTotal, 4800);
      expect(line.isNegotiated, isTrue);
    });

    test('a line booked at list price is not flagged as negotiated', () {
      final OrderPackaging line = _firstOrder().packagings.last;

      expect(line.isNegotiated, isFalse);
      expect(line.lineTotal, 1200);
    });

    test('bags are counted across every line', () {
      final Order order = _firstOrder();

      expect(order.packagings, hasLength(2));
      // 2 bags on the first line plus 1 on the second.
      expect(order.bagCount, 3);
    });

    test('verification fields are read off the payload', () {
      final Order order = _firstOrder();

      expect(order.isVerified, isTrue);
      expect(order.verifiedBy, 'Priya Admin');
      expect(order.verifiedAt, isNotNull);
    });

    test('an unverified order has no verifier and no timestamp', () {
      final Order order = Order.fromJson(const {
        'public_id': 'O-1',
        'verified': false,
        'verified_by': null,
        'verified_at': null,
      });

      expect(order.isVerified, isFalse);
      expect(order.verifiedBy, '');
      expect(order.verifiedAt, isNull);
    });

    test('dispatch mode distinguishes agency from own vehicle', () {
      expect(_firstOrder().isAgencyDispatch, isTrue);

      const private = Order(publicId: 'O-2', dispatchMode: 'PRIVATE');
      expect(private.isAgencyDispatch, isFalse);
    });

    test('a null city leaves the name blank rather than crashing', () {
      final Order order = Order.fromJson(const {
        'public_id': 'O-1',
        'city': null,
      });

      expect(order.city, isNull);
      expect(order.cityName, '');
    });

    test('the envelope carries filters and sorts for the sheet', () {
      final PaginatedOrders page = PaginatedOrders.fromJson(
        Map<String, dynamic>.from(jsonDecode(_page) as Map),
      );

      expect(page.totalCount, 2);
      expect(page.nextPageNumber, isNull);
      expect(page.availableFilters.single.key, 'city_id');
      expect(page.availableSorts.single.key, 'created_at');
    });
  });

  group('order status', () {
    test('every backend code maps to its own case', () {
      expect(OrderStatusX.fromRaw('BOOKED'), OrderStatus.booked);
      expect(OrderStatusX.fromRaw('UNDER_REVIEW'), OrderStatus.underReview);
      expect(OrderStatusX.fromRaw('CONFIRMED'), OrderStatus.confirmed);
      expect(OrderStatusX.fromRaw('DISPATCHED'), OrderStatus.dispatched);
      expect(OrderStatusX.fromRaw('DELIVERED'), OrderStatus.delivered);
      expect(OrderStatusX.fromRaw('ON_HOLD'), OrderStatus.onHold);
      expect(OrderStatusX.fromRaw('REJECTED'), OrderStatus.rejected);
    });

    test('an unknown or empty code falls back rather than throwing', () {
      expect(OrderStatusX.fromRaw('SOMETHING_NEW'), OrderStatus.unknown);
      expect(OrderStatusX.fromRaw(''), OrderStatus.unknown);
    });

    test('every status has a human label', () {
      for (final OrderStatus status in OrderStatus.values) {
        expect(OrderStatusX.labelOf(status), isNotEmpty);
      }
    });
  });

  group('backend-supplied labels', () {
    test('a filter shows the label the backend sent', () {
      const filter = ClientFilter(
        key: 'city_id',
        label: 'Delivery city',
        kind: FilterKind.select,
      );

      expect(filter.title, 'Delivery city');
    });

    test('a filter with no label falls back to a humanised key', () {
      const filter = ClientFilter(key: 'city_id', kind: FilterKind.select);

      expect(filter.title, 'City');
    });

    test('a sort shows the label the backend sent', () {
      const sort = ClientSort(key: 'created_at', label: 'Created');

      expect(sort.title, 'Created');
    });
  });
}
