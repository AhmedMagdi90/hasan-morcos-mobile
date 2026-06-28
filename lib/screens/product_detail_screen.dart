import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    required this.product,
    required this.onAddToCart,
    super.key,
  });

  final Product product;
  final ValueChanged<Product> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final canAdd = product.availableQuantity > 0;

    return Scaffold(
      appBar: AppBar(title: Text(product.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ProductImage(
              imagePath: product.image,
              size: 220,
              borderRadius: 24,
            ),
          ),
          const SizedBox(height: 24),
          Text(product.displayName, style: Theme.of(context).textTheme.headlineSmall),
          if (product.nameEn.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(product.nameEn),
          ],
          const SizedBox(height: 16),
          Text(
            '${product.price.toStringAsFixed(2)} EGP',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Stock ${product.availableQuantity}')),
              if (product.category.isNotEmpty) Chip(label: Text(product.category)),
              if (product.sku.isNotEmpty) Chip(label: Text('SKU ${product.sku}')),
              if (product.variantSku.isNotEmpty) Chip(label: Text('Variant ${product.variantSku}')),
              if (product.barcode.isNotEmpty) Chip(label: Text('Barcode ${product.barcode}')),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: canAdd
                ? () {
                    onAddToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added to cart.')),
                    );
                  }
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(canAdd ? 'Add To Cart' : 'Out Of Stock'),
          ),
        ],
      ),
    );
  }
}
