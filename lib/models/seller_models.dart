enum ListingStatus { active, outOfStock, paused }

class SellerListing {
  final String id;
  final String name;
  final double price;
  final String unit;
  final int stock;
  final ListingStatus status;

  const SellerListing({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.stock,
    required this.status,
  });
}

enum IncomingOrderStatus { newOrder, confirmed, shipped, delivered }

class IncomingOrder {
  final String id;
  final String growerName;
  final DateTime date;
  final String itemSummary;
  final double total;
  final IncomingOrderStatus status;

  const IncomingOrder({
    required this.id,
    required this.growerName,
    required this.date,
    required this.itemSummary,
    required this.total,
    required this.status,
  });
}
