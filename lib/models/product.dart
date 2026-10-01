enum ProductCategory { fertilizer, pesticide, tool, box, other }

class Product {
  final String id;
  final String name;
  final double price;
  final String unit; // e.g. "50 Kg", "Ltr", "piece"
  final ProductCategory category;
  final String? imageUrl;
  final String sellerName;
  final String sellerId;
  final int stock;
  final String? description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.category,
    this.imageUrl,
    required this.sellerName,
    this.sellerId = '',
    this.stock = 100,
    this.description,
  });
}