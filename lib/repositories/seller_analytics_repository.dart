import '../main.dart';

class ProductRevenue {
  final String productName;
  final double revenue;
  final int unitsSold;
  const ProductRevenue({required this.productName, required this.revenue, required this.unitsSold});
}

class SellerAnalytics {
  final double totalSales;
  final int totalOrders;
  final double avgOrderValue;
  final List<double> weekSales; // oldest -> today
  final List<ProductRevenue> topProducts;

  const SellerAnalytics({
    required this.totalSales,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.weekSales,
    required this.topProducts,
  });
}

class SellerAnalyticsRepository {
  /// Every number here is derived from real orders/order_items — no page
  /// views or conversion-rate metrics, since this app doesn't track those.
  static Future<SellerAnalytics> fetch() async {
    final sellerId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('orders')
        .select('id, total, created_at, order_items(product_name, quantity, unit_price)')
        .eq('seller_id', sellerId)
        .neq('status', 'cancelled');

    final orderRows = (rows as List).cast<Map<String, dynamic>>();

    double totalSales = 0;
    final now = DateTime.now();
    final weekSales = List<double>.filled(7, 0);
    final revenueByProduct = <String, double>{};
    final unitsByProduct = <String, int>{};

    for (final row in orderRows) {
      final total = (row['total'] as num).toDouble();
      totalSales += total;
      final date = DateTime.parse(row['created_at'] as String);
      final daysAgo = now.difference(date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        weekSales[6 - daysAgo] += total;
      }
      for (final item in (row['order_items'] as List)) {
        final name = item['product_name'] as String;
        final qty = (item['quantity'] as num).toInt();
        final price = (item['unit_price'] as num).toDouble();
        revenueByProduct[name] = (revenueByProduct[name] ?? 0) + qty * price;
        unitsByProduct[name] = (unitsByProduct[name] ?? 0) + qty;
      }
    }

    final topProducts = revenueByProduct.entries
        .map((e) => ProductRevenue(productName: e.key, revenue: e.value, unitsSold: unitsByProduct[e.key] ?? 0))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return SellerAnalytics(
      totalSales: totalSales,
      totalOrders: orderRows.length,
      avgOrderValue: orderRows.isEmpty ? 0 : totalSales / orderRows.length,
      weekSales: weekSales,
      topProducts: topProducts.take(5).toList(),
    );
  }
}
