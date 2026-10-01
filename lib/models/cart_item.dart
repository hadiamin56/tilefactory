class CartItem {
  final String id; // cart_items row id
  final String listingId;
  final String productName;
  final double unitPrice;
  final String unit;
  final int stock;
  final String sellerId;
  final String sellerName;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.id,
    required this.listingId,
    required this.productName,
    required this.unitPrice,
    required this.unit,
    required this.stock,
    required this.sellerId,
    required this.sellerName,
    required this.quantity,
    this.imageUrl,
  });

  double get total => unitPrice * quantity;
}
