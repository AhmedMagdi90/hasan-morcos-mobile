import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
  });

  final Product product;
  int quantity;

  double get lineTotal => product.price * quantity;

  Map<String, dynamic> toOrderJson() {
    return {
      'variant_id': product.variantId,
      'quantity': quantity,
    };
  }
}
