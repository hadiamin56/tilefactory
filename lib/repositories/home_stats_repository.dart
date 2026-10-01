import '../main.dart';

class HomeStats {
  final double walletBalance;
  final int activeOrders;
  final double totalSales;
  final int profileViews;
  final bool isVerified;
  final String name;

  const HomeStats({
    required this.walletBalance,
    required this.activeOrders,
    required this.totalSales,
    required this.profileViews,
    required this.isVerified,
    required this.name,
  });
}

class HomeStatsRepository {
  static Future<HomeStats> fetchGrowerStats() async {
    final userId = supabase.auth.currentUser!.id;

    final profile = await supabase
        .from('profiles')
        .select('wallet_balance, is_verified, full_name')
        .eq('id', userId)
        .single();

    final activeOrdersRows = await supabase
        .from('orders')
        .select('id')
        .eq('grower_id', userId)
        .inFilter('status', ['pending', 'confirmed', 'shipped']);

    return HomeStats(
      walletBalance: (profile['wallet_balance'] as num).toDouble(),
      activeOrders: (activeOrdersRows as List).length,
      // Total Sales & Profile Views apply once a Grower can sell produce
      // (Phase 2) — kept at 0 until that feature ships.
      totalSales: 0,
      profileViews: 0,
      isVerified: profile['is_verified'] as bool,
      name: (profile['full_name'] as String?) ?? 'Grower',
    );
  }
}