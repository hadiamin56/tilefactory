import '../models/product.dart';
import '../models/order.dart';
import '../models/market_price.dart';
import '../models/seller_models.dart';

/// Temporary in-memory data so the UI is testable before Supabase is wired up.
/// Replace each of these with a repository/service call to Supabase later —
/// screens should not need to change, only where this data comes from.
class MockData {
  static final List<Product> inputs = [
    const Product(
      id: 'p1',
      name: 'DAP Fertilizer',
      price: 1350,
      unit: '50 Kg',
      category: ProductCategory.fertilizer,
      sellerId: 's1', sellerName: 'Kashmir AgroSupplies',
    ),
    const Product(
      id: 'p2',
      name: 'Urea Fertilizer',
      price: 266,
      unit: '45 Kg',
      category: ProductCategory.fertilizer,
      sellerId: 's1', sellerName: 'Kashmir AgroSupplies',
    ),
    const Product(
      id: 'p3',
      name: 'Neem Oil',
      price: 650,
      unit: 'Ltr',
      category: ProductCategory.pesticide,
      sellerId: 's3', sellerName: 'GreenGuard Agro',
    ),
    const Product(
      id: 'p4',
      name: 'Imidacloprid 17.8 SL',
      price: 980,
      unit: 'Ltr',
      category: ProductCategory.pesticide,
      sellerId: 's3', sellerName: 'GreenGuard Agro',
    ),
    const Product(
      id: 'p5',
      name: 'Fruit Packing Boxes (Apple)',
      price: 45,
      unit: 'piece',
      category: ProductCategory.box,
      sellerId: 's2', sellerName: 'Valley Packaging Co.',
    ),
    const Product(
      id: 'p6',
      name: 'Pruning Shears',
      price: 850,
      unit: 'piece',
      category: ProductCategory.tool,
      sellerName: 'FarmTools Kashmir',
    ),
  ];

  static final List<MarketPrice> marketPrices = [
    const MarketPrice(produceName: 'Apple (High Density)', pricePerKg: 75.00, changePercent: 2.35),
    const MarketPrice(produceName: 'Walnuts', pricePerKg: 220.00, changePercent: -1.10),
    const MarketPrice(produceName: 'Cherries', pricePerKg: 160.00, changePercent: 3.40),
    const MarketPrice(produceName: 'Almonds', pricePerKg: 320.00, changePercent: 0.80),
  ];

  static final List<GrowerOrder> orders = [
    GrowerOrder(
      id: 'ORD-1042',
      date: DateTime.now().subtract(const Duration(days: 1)),
      sellerId: 's1', sellerName: 'Kashmir AgroSupplies',
      status: OrderStatus.shipped,
      items: const [
        OrderItem(productName: 'DAP Fertilizer', quantity: 2, unitPrice: 1350),
      ],
    ),
    GrowerOrder(
      id: 'ORD-1039',
      date: DateTime.now().subtract(const Duration(days: 5)),
      sellerId: 's2', sellerName: 'Valley Packaging Co.',
      status: OrderStatus.delivered,
      items: const [
        OrderItem(productName: 'Fruit Packing Boxes (Apple)', quantity: 200, unitPrice: 45),
      ],
    ),
    GrowerOrder(
      id: 'ORD-1051',
      date: DateTime.now(),
      sellerId: 's3', sellerName: 'GreenGuard Agro',
      status: OrderStatus.pending,
      items: const [
        OrderItem(productName: 'Neem Oil', quantity: 3, unitPrice: 650),
      ],
    ),
  ];

  // Dashboard stat placeholders
  static const activeOrders = 12;
  static const totalSales = 248500.0;
  static const walletBalance = 18750.0;
  static const profileViews = 342;
  static const growerName = 'Aijaz Ahmad';
  static const growerLocation = 'Srinagar, Kashmir';

  // --- Seller side ---
  static const sellerBusinessName = 'Kashmir AgroSupplies';
  static const sellerActiveOrders = 8;
  static const sellerTotalSales = 96400.0;
  static const sellerWalletBalance = 42200.0;

  static final List<SellerListing> sellerListings = [
    const SellerListing(id: 'l1', name: 'DAP Fertilizer', price: 1350, unit: '50 Kg', stock: 40, status: ListingStatus.active),
    const SellerListing(id: 'l2', name: 'Urea Fertilizer', price: 266, unit: '45 Kg', stock: 0, status: ListingStatus.outOfStock),
    const SellerListing(id: 'l3', name: 'NPK 19:19:19', price: 1180, unit: '50 Kg', stock: 25, status: ListingStatus.active),
    const SellerListing(id: 'l4', name: 'Sprayer Pump (Manual)', price: 1450, unit: 'piece', stock: 12, status: ListingStatus.paused),
  ];

  static final List<IncomingOrder> sellerOrders = [
    IncomingOrder(id: 'ORD-1042', growerName: 'Aijaz Ahmad', date: DateTime.now().subtract(const Duration(days: 1)), itemSummary: 'DAP Fertilizer x2', total: 2700, status: IncomingOrderStatus.shipped),
    IncomingOrder(id: 'ORD-1055', growerName: 'Bilal Rather', date: DateTime.now(), itemSummary: 'NPK 19:19:19 x1', total: 1180, status: IncomingOrderStatus.newOrder),
    IncomingOrder(id: 'ORD-1048', growerName: 'Farooq Dar', date: DateTime.now().subtract(const Duration(days: 3)), itemSummary: 'DAP Fertilizer x4', total: 5400, status: IncomingOrderStatus.delivered),
  ];
}
