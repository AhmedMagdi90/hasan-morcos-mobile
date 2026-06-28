class Product {
  const Product({
    required this.variantId,
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.sku,
    required this.variantSku,
    required this.barcode,
    required this.price,
    required this.availableQuantity,
    required this.image,
  });

  final int variantId;
  final int productId;
  final String nameAr;
  final String nameEn;
  final String category;
  final String sku;
  final String variantSku;
  final String barcode;
  final double price;
  final int availableQuantity;
  final String image;

  String get displayName => nameAr.isNotEmpty ? nameAr : nameEn;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      variantId: json['variant_id'] as int,
      productId: json['product_id'] as int,
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantSku: json['variant_sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      availableQuantity: json['available_quantity'] as int? ?? 0,
      image: json['image']?.toString() ?? '',
    );
  }
}
