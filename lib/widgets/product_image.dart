import 'package:flutter/material.dart';

import '../config/api_config.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.imagePath,
    this.size = 64,
    this.borderRadius = 12,
    super.key,
  });

  final String imagePath;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.absoluteUrl(imagePath);

    if (imageUrl.isEmpty) {
      return placeholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(context),
      ),
    );
  }

  Widget placeholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }
}
