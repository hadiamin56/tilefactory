import '../main.dart';
import '../models/cart_item.dart';

class CartRepository {
  /// Fetch the current grower's cart, joined with live listing data (so
  /// price/stock always reflect what the seller has right now).
  static Future<List<CartItem>> fetchCart() async {
    final growerId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('cart_items')
        .select('id, quantity, listing_id, listings(name, price, unit, stock, seller_id, image_url)')
        .eq('grower_id', growerId)
        .order('created_at');

    final cartRows = (rows as List).cast<Map<String, dynamic>>();
    final sellerIds = cartRows.map((r) => (r['listings'] as Map)['seller_id'] as String).toSet().toList();
    final nameBySeller = await _fetchBusinessNames(sellerIds);

    return cartRows.map((row) {
      final listing = row['listings'] as Map<String, dynamic>;
      final sellerId = listing['seller_id'] as String;
      return CartItem(
        id: row['id'] as String,
        listingId: row['listing_id'] as String,
        productName: listing['name'] as String,
        unitPrice: (listing['price'] as num).toDouble(),
        unit: listing['unit'] as String,
        stock: (listing['stock'] as num?)?.toInt() ?? 0,
        sellerId: sellerId,
        sellerName: nameBySeller[sellerId] ?? 'Seller',
        quantity: (row['quantity'] as num).toInt(),
        imageUrl: listing['image_url'] as String?,
      );
    }).toList();
  }

  static Future<Map<String, String>> _fetchBusinessNames(List<String> sellerIds) async {
    if (sellerIds.isEmpty) return {};
    final rows = await supabase.from('profiles_public').select('id, business_name').inFilter('id', sellerIds);
    final map = <String, String>{};
    for (final row in (rows as List)) {
      map[row['id'] as String] = (row['business_name'] as String?) ?? 'Seller';
    }
    return map;
  }

  /// Total item count across the cart, for the app-bar badge.
  static Future<int> fetchItemCount() async {
    final growerId = supabase.auth.currentUser!.id;
    final rows = await supabase.from('cart_items').select('quantity').eq('grower_id', growerId);
    return (rows as List).fold<int>(0, (sum, r) => sum + ((r['quantity'] as num).toInt()));
  }

  /// Add a listing to the cart, or bump quantity if it's already there.
  static Future<void> addToCart(String listingId, int quantity) async {
    final growerId = supabase.auth.currentUser!.id;
    final existing = await supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('grower_id', growerId)
        .eq('listing_id', listingId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('cart_items').insert({
        'grower_id': growerId,
        'listing_id': listingId,
        'quantity': quantity,
      });
    } else {
      final newQty = (existing['quantity'] as num).toInt() + quantity;
      await supabase.from('cart_items').update({'quantity': newQty}).eq('id', existing['id'] as String);
    }
  }

  static Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    await supabase.from('cart_items').update({'quantity': quantity}).eq('id', cartItemId);
  }

  static Future<void> removeItem(String cartItemId) async {
    await supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  static Future<void> clearCart() async {
    final growerId = supabase.auth.currentUser!.id;
    await supabase.from('cart_items').delete().eq('grower_id', growerId);
  }

  /// Places one order per seller represented in [items] (a marketplace cart
  /// can span multiple sellers; each seller only ever sees their own order),
  /// debits the wallet once per seller order, decrements stock per line item,
  /// then empties the cart. Returns the number of orders created.
  static Future<int> checkout({
    required List<CartItem> items,
    required String deliveryName,
    required String deliveryPhone,
    required String deliveryAddress,
  }) async {
    final growerId = supabase.auth.currentUser!.id;

    final grandTotal = items.fold<double>(0, (sum, it) => sum + it.total);
    final profile = await supabase.from('profiles').select('wallet_balance').eq('id', growerId).single();
    final balance = (profile['wallet_balance'] as num).toDouble();
    if (balance < grandTotal) {
      throw InsufficientBalanceException(balance: balance, required: grandTotal);
    }

    final bySeller = <String, List<CartItem>>{};
    for (final item in items) {
      bySeller.putIfAbsent(item.sellerId, () => []).add(item);
    }

    for (final entry in bySeller.entries) {
      final sellerId = entry.key;
      final sellerItems = entry.value;
      final orderTotal = sellerItems.fold<double>(0, (sum, it) => sum + it.total);

      final orderRow = await supabase
          .from('orders')
          .insert({
            'grower_id': growerId,
            'seller_id': sellerId,
            'status': 'pending',
            'total': orderTotal,
            'delivery_name': deliveryName,
            'delivery_phone': deliveryPhone,
            'delivery_address': deliveryAddress,
          })
          .select()
          .single();

      for (final item in sellerItems) {
        await supabase.from('order_items').insert({
          'order_id': orderRow['id'],
          'listing_id': item.listingId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        });
        await supabase.rpc('decrement_listing_stock', params: {
          'p_listing_id': item.listingId,
          'p_quantity': item.quantity,
        });
      }

      await supabase.rpc('adjust_wallet_balance', params: {
        'p_user_id': growerId,
        'p_amount': -orderTotal,
      });
      await supabase.from('wallet_transactions').insert({
        'user_id': growerId,
        'label': 'Order payment — ${sellerItems.length} item(s)',
        'amount': -orderTotal,
      });
    }

    await clearCart();
    return bySeller.length;
  }

  /// Grower's saved default address, prefilled at checkout.
  static Future<String?> fetchSavedAddress() async {
    final growerId = supabase.auth.currentUser!.id;
    final row = await supabase.from('profiles').select('saved_address').eq('id', growerId).maybeSingle();
    return row?['saved_address'] as String?;
  }

  static Future<void> saveDefaultAddress(String address) async {
    final growerId = supabase.auth.currentUser!.id;
    await supabase.from('profiles').update({'saved_address': address}).eq('id', growerId);
  }
}

class InsufficientBalanceException implements Exception {
  final double balance;
  final double required;
  const InsufficientBalanceException({required this.balance, required this.required});

  double get shortfall => required - balance;
}
