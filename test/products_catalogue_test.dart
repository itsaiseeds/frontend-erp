import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/products/data/models/cart_line.dart';
import 'package:frontend_erp/features/products/data/models/paginated_products.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/data/models/products_query.dart';
import 'package:frontend_erp/features/clients/data/models/client_address.dart';
import 'package:frontend_erp/features/clients/data/models/transport_agency.dart';

void main() {
  group('catalogue parsing', () {
    test('reads a bag row with its nested product and stage', () {
      final page = PaginatedProducts.fromJson({
        'total_count': 2,
        'total_pages': 1,
        'next_page_number': null,
        'previous_page_number': null,
        'results': [
          {
            'public_id': 'PP-U4UYPFOF08NZ',
            'name': 'SAI-33 40x1kg',
            'packets': 40,
            'packet_weight': '1.0',
            'total_weight': '40.0',
            'selling_price': '4800.0',
            'product': {
              'public_id': 'P-I34V7RI1JPUH',
              'name': 'SAI-33',
              'crop': 'Castor',
              'stage': {'code': 'BREEDER', 'name': 'Breeder', 'sequence': 1},
              'image_url': '/media/products/x.jpg',
              'description_items': ['High yield'],
            },
          },
        ],
        'available_filters': [],
        'available_sorts': [],
      });

      expect(page.totalCount, 2);
      expect(page.results.length, 1);

      final row = page.results.first;
      expect(row.publicId, 'PP-U4UYPFOF08NZ');
      expect(row.productName, 'SAI-33');
      expect(row.stageName, 'Breeder');
      expect(row.packets, 40);
      expect(row.packetWeight, 1.0);
      expect(row.totalWeight, 40.0);
      expect(row.sellingPrice, 4800.0);
      expect(row.descriptionItems, ['High yield']);
    });

    test('tolerates a row with no product block', () {
      final row = ProductPackaging.fromJson({'public_id': 'PP-1'});

      expect(row.productName, '');
      expect(row.stageName, '');
      expect(row.sellingPrice, 0);
      expect(row.descriptionItems, isEmpty);
    });
  });

  group('cart', () {
    const bag = ProductPackaging(publicId: 'PP-1', sellingPrice: 4800);

    test('line total multiplies the bag price by quantity', () {
      expect(const CartLine(packaging: bag, quantity: 3).lineTotal, 14400);
    });

    test('copyWith changes only the quantity', () {
      const line = CartLine(packaging: bag, quantity: 1);
      expect(line.copyWith(quantity: 5).quantity, 5);
      expect(line.copyWith(quantity: 5).packaging, bag);
    });
  });

  group('query parameters', () {
    test('search uses the name param the catalogue expects', () {
      const query = ProductsQuery(name: 'SAI');

      final params = query.toQueryParameters(
        page: 1,
        pageSize: 10,
        rangeParamsByKey: const {},
      );

      expect(params['name'], 'SAI');
      expect(params['page'], 1);
      expect(params['page_size'], 10);
    });

    test('selections join with commas and sort carries direction', () {
      final query = const ProductsQuery()
          .withSelection('stage', {'BREEDER', 'RESEARCH'})
          .copyWith(sort: 'selling_price', descending: true);

      final params = query.toQueryParameters(
        page: 2,
        pageSize: 10,
        rangeParamsByKey: const {},
      );

      expect(params['stage'], 'BREEDER,RESEARCH');
      expect(params['sort'], '-selling_price');
    });
  });

  group('client payload link ids', () {
    test('an address carries the id the order endpoint needs', () {
      final address = ClientAddress.fromJson({
        'id': 7,
        'label': 'Shop',
        'is_primary': true,
        'line_1': 'Line 1',
        'city': 'Rajkot',
        'state': 'Gujarat',
        'pincode': '360001',
      });

      expect(address.id, 7);
      expect(address.label, 'Shop');
      expect(address.isPrimary, isTrue);
    });

    test('an agency carries the id the order endpoint needs', () {
      final agency = TransportAgency.fromJson({
        'id': 3,
        'name': 'Speedy Transport',
        'is_primary': false,
      });

      expect(agency.id, 3);
      expect(agency.name, 'Speedy Transport');
    });

    test('a link id defaults to zero when the API omits it', () {
      expect(ClientAddress.fromJson({'line_1': 'x'}).id, 0);
      expect(TransportAgency.fromJson({'name': 'x'}).id, 0);
    });
  });
}
