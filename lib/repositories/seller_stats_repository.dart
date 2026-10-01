import '../main.dart';

class SellerStats {
  final double walletBalance;
  final int activeOrders;
  final double totalSales;
  final int listingsCount;
  final List<double> weekSales; // last 7 days, oldest first — for the trend bar chart

  const SellerStats({
    required this.walletBalance,
    required this.activeOrders,
    required this.totalSales,
    required this.listingsCount,
    required this.weekSales,
  });
}

class SellerStatsRepository {
  static Future<SellerStats> fetch() async {
    final sellerId = supabase.auth.currentUser!.id;

    final profile = await supabase.from('profiles').select('wallet_balance').eq('id', sellerId).single();

    final activeOrdersRows = await supabase
        .from('orders')
        .select('id')
        .eq('seller_id', sellerId)
        .inFilter('status', ['pending', 'confirmed', 'shipped']);

    final allOrders = await supabase
        .from('orders')
        .select('total, status, created_at')
        .eq('seller_id', sellerId)
        .neq('status', 'cancelled');

    final listingsRows = await supabase.from('listings').select('id').eq('seller_id', sellerId);

    double totalSales = 0;
    final now = DateTime.now();
    final weekSales = List<double>.filled(7, 0);
    for (final row in (allOrders as List)) {
      final total = (row['total'] as num).toDouble();
      totalSales += total;
      final date = DateTime.parse(row['created_at'] as String);
      final daysAgo = now.difference(date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        weekSales[6 - daysAgo] += total;
      }
    }

    return SellerStats(
      walletBalance: (profile['wallet_balance'] as num).toDouble(),
      activeOrders: (activeOrdersRows as List).length,
      totalSales: totalSales,
      listingsCount: (listingsRows as List).length,
      weekSales: weekSales,
    );
  }
}