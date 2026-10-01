enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

class OrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class GrowerOrder {
  final String id;
  final DateTime date;
  final String sellerId;
  final String sellerName;
  final List<OrderItem> items;
  final OrderStatus status;
  final String? deliveryName;
  final String? deliveryPhone;
  final String? deliveryAddress;

  const GrowerOrder({
    required this.id,
    required this.date,
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.status,
    this.deliveryName,
    this.deliveryPhone,
    this.deliveryAddress,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);
}
