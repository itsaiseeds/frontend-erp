import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/products/data/models/cart_line.dart';
import 'package:frontend_erp/features/products/data/models/product_packaging.dart';
import 'package:frontend_erp/features/products/presentation/bloc/products_state.dart';

const _bagA = ProductPackaging(
  publicId: 'PP-A',
  productName: 'SAI-33',
  sellingPrice: 4800,
);
const _bagB = ProductPackaging(
  publicId: 'PP-B',
  productName: 'SAI-3353',
  sellingPrice: 5000,
);

ProductsState _withCart(Map<String, CartLine> cart) =>
    ProductsState(cart: cart);

void main() {
  group('cart totals', () {
    test('an empty cart has no items, no total and no bar', () {
      const state = ProductsState();

      expect(state.cartItemCount, 0);
      expect(state.cartTotal, 0);
      expect(state.hasCart, isFalse);
    });

    test('counts packets across lines, not just distinct products', () {
      final state = _withCart({
        'PP-A': const CartLine(packaging: _bagA, quantity: 2),
        'PP-B': const CartLine(packaging: _bagB, quantity: 1),
      });

      expect(state.cartItemCount, 3);
      expect(state.cartTotal, 4800 * 2 + 5000);
      expect(state.hasCart, isTrue);
    });

    test('quantityOf reports zero for a product not in the cart', () {
      final state = _withCart({
        'PP-A': const CartLine(packaging: _bagA, quantity: 2),
      });

      expect(state.quantityOf('PP-A'), 2);
      expect(state.quantityOf('PP-B'), 0);
    });
  });

  group('cart line', () {
    test('line total is the bag price times quantity', () {
      expect(const CartLine(packaging: _bagA, quantity: 3).lineTotal, 14400);
    });

    test('a single bag costs its own price', () {
      expect(const CartLine(packaging: _bagA).lineTotal, 4800);
    });
  });
}
