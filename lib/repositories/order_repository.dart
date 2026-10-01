import '../main.dart';
import '../models/order.dart';

class OrderRepository {
  /// Grower cancels their own still-pending order — refunds the wallet.
  static Future<void> cancelOrder(String orderId) async {
    final growerId = supabase.auth.currentUser!.id;
    final order = await supabase.from('orders').select('total, status').eq('id', orderId).single();
    if (order['status'] != 'pending') {
      throw Exception('Only pending orders can be cancelled');
    }
    await supabase.from('orders').update({'status': 'cancelled'}).eq('id', orderId);
    final total = (order['total'] as num).toDouble();
    await supabase.rpc('adjust_wallet_balance', params: {
      'p_user_id': growerId,
      'p_amount': total,
    });
    await supabase.from('wallet_transactions').insert({
      'user_id': growerId,
      'label': 'Refund — order cancelled',
      'amount': total,
    });
  }

  /// Grower: fetch their own order history.
  static Future<List<GrowerOrder>> fetchMyOrders() async {
    final growerId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('orders')
        .select('id, seller_id, status, created_at, delivery_name, delivery_phone, delivery_address, order_items(product_name, quantity, unit_price)')
        .eq('grower_id', growerId)
        .order('created_at', ascending: false);

    final orderRows = (rows as List).cast<Map<String, dynamic>>();
    final sellerIds = orderRows.map((r) => r['seller_id'] as String).toSet().toList();
    final nameById = await _fetchPublicNames(sellerIds);

    return orderRows.map((row) {
      final items = (row['order_items'] as List)
          .map((it) => OrderItem(
                productName: it['product_name'] as String,
                quantity: (it['quantity'] as num).toInt(),
                unitPrice: (it['unit_price'] as num).toDouble(),
              ))
          .toList();
      return GrowerOrder(
        id: row['id'] as String,
        date: DateTime.parse(row['created_at'] as String),
        sellerId: row['seller_id'] as String,
        sellerName: nameById[row['seller_id']] ?? 'Seller',
        items: items,
        status: _statusFromString(row['status'] as String),
        deliveryName: row['delivery_name'] as String?,
        deliveryPhone: row['delivery_phone'] as String?,
        deliveryAddress: row['delivery_address'] as String?,
      );
    }).toList();
  }

  /// Seller: fetch orders placed against their listings.
  static Future<List<Map<String, dynamic>>> fetchIncomingOrders() async {
    final sellerId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('orders')
        .select('id, grower_id, status, total, created_at, order_items(product_name, quantity)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    final orderRows = (rows as List).cast<Map<String, dynamic>>();
    final growerIds = orderRows.map((r) => r['grower_id'] as String).toSet().toList();
    final nameById = await _fetchPublicNames(growerIds);

    for (final row in orderRows) {
      row['grower_name'] = nameById[row['grower_id']] ?? 'Grower';
    }
    return orderRows;
  }

  static Future<Map<String, String>> _fetchPublicNames(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await supabase.from('profiles_public').select('id, full_name, business_name').inFilter('id', ids);
    final map = <String, String>{};
    for (final row in (rows as List)) {
      map[row['id'] as String] = (row['business_name'] as String?) ?? (row['full_name'] as String?) ?? 'User';
    }
    return map;
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await supabase.from('orders').update({'status': newStatus}).eq('id', orderId);
  }

  /// Seller cancels/rejects an order they can't fulfill (e.g. went out of
  /// stock) — only while it hasn't shipped yet. Refunds the grower's wallet
  /// and restocks the listings.
  static Future<void> sellerCancelOrder(String orderId) async {
    final order = await supabase.from('orders').select('grower_id, total, status').eq('id', orderId).single();
    final status = order['status'] as String;
    if (status == 'shipped' || status == 'delivered' || status == 'cancelled') {
      throw Exception('This order can no longer be cancelled');
    }
    final growerId = order['grower_id'] as String;
    final total = (order['total'] as num).toDouble();

    await supabase.from('orders').update({'status': 'cancelled'}).eq('id', orderId);

    await supabase.rpc('adjust_wallet_balance', params: {'p_user_id': growerId, 'p_amount': total});
    await supabase.from('wallet_transactions').insert({
      'user_id': growerId,
      'label': 'Refund — order cancelled by seller',
      'amount': total,
    });

    final items = await supabase.from('order_items').select('listing_id, quantity').eq('order_id', orderId);
    for (final item in (items as List)) {
      // Negative quantity to the existing decrement RPC adds the stock back.
      await supabase.rpc('decrement_listing_stock', params: {
        'p_listing_id': item['listing_id'],
        'p_quantity': -(item['quantity'] as num).toInt(),
      });
    }
  }

  static OrderStatus _statusFromString(String s) {
    return OrderStatus.values.firstWhere((e) => e.name == s, orElse: () => OrderStatus.pending);
  }
}