import 'package:equatable/equatable.dart';

import 'product_packaging.dart';

class CartLine extends Equatable {
  final ProductPackaging packaging;
  final int quantity;

  const CartLine({required this.packaging, this.quantity = 1});

  num get lineTotal => packaging.sellingPrice * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(packaging: packaging, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [packaging, quantity];
}
