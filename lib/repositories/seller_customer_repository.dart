import '../main.dart';

class SellerCustomer {
  final String growerId;
  final String growerName;
  final int orderCount;
  final double totalSpent;
  final DateTime lastOrderAt;

  const SellerCustomer({
    required this.growerId,
    required this.growerName,
    required this.orderCount,
    required this.totalSpent,
    required this.lastOrderAt,
  });
}

class SellerCustomerRepository {
  /// Aggregates the seller's own order history into a per-grower customer
  /// list — real numbers only, no invented CRM data.
  static Future<List<SellerCustomer>> fetchCustomers() async {
    final sellerId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('orders')
        .select('grower_id, total, created_at, status')
        .eq('seller_id', sellerId)
        .neq('status', 'cancelled');

    final orderRows = (rows as List).cast<Map<String, dynamic>>();
    final byGrower = <String, List<Map<String, dynamic>>>{};
    for (final row in orderRows) {
      byGrower.putIfAbsent(row['grower_id'] as String, () => []).add(row);
    }

    final growerIds = byGrower.keys.toList();
    final names = <String, String>{};
    if (growerIds.isNotEmpty) {
      final nameRows = await supabase.from('profiles_public').select('id, full_name').inFilter('id', growerIds);
      for (final row in (nameRows as List)) {
        names[row['id'] as String] = (row['full_name'] as String?) ?? 'Grower';
      }
    }

    final customers = byGrower.entries.map((entry) {
      final orders = entry.value;
      final total = orders.fold<double>(0, (sum, o) => sum + (o['total'] as num).toDouble());
      final lastOrder = orders.map((o) => DateTime.parse(o['created_at'] as String)).reduce((a, b) => a.isAfter(b) ? a : b);
      return SellerCustomer(
        growerId: entry.key,
        growerName: names[entry.key] ?? 'Grower',
        orderCount: orders.length,
        totalSpent: total,
        lastOrderAt: lastOrder,
      );
    }).toList();

    customers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return customers;
  }
}
