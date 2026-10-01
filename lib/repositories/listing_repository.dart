import 'dart:typed_data';
import '../main.dart';
import '../models/product.dart';

class ListingRepository {
  /// Fetch all active input listings, from any Seller.
  /// Seller names are looked up from `profiles_public` (a view that
  /// excludes private fields like phone/location/wallet_balance) since
  /// PostgREST can't auto-embed relationships through a view.
  static Future<List<Product>> fetchActiveListings() async {
    final rows = await supabase
        .from('listings')
        .select('id, name, price, unit, category, seller_id, stock, image_url, description')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final listingRows = (rows as List).cast<Map<String, dynamic>>();
    final sellerIds = listingRows.map((r) => r['seller_id'] as String).toSet().toList();
    final nameBySeller = await _fetchBusinessNames(sellerIds);

    return listingRows.map((row) {
      return Product(
        id: row['id'] as String,
        name: row['name'] as String,
        price: (row['price'] as num).toDouble(),
        unit: row['unit'] as String,
        category: _categoryFromString(row['category'] as String),
        imageUrl: row['image_url'] as String?,
        sellerName: nameBySeller[row['seller_id']] ?? 'Seller',
        sellerId: row['seller_id'] as String,
        stock: (row['stock'] as num?)?.toInt() ?? 0,
        description: row['description'] as String?,
      );
    }).toList();
  }

  /// Grower-facing: fetch a specific seller's active listings, for the
  /// public Store page reached from a product's seller card.
  static Future<List<Product>> fetchListingsBySeller(String sellerId, {required String sellerName}) async {
    final rows = await supabase
        .from('listings')
        .select('id, name, price, unit, category, seller_id, stock, image_url, description')
        .eq('seller_id', sellerId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final listingRows = (rows as List).cast<Map<String, dynamic>>();
    return listingRows.map((row) {
      return Product(
        id: row['id'] as String,
        name: row['name'] as String,
        price: (row['price'] as num).toDouble(),
        unit: row['unit'] as String,
        category: _categoryFromString(row['category'] as String),
        imageUrl: row['image_url'] as String?,
        sellerName: sellerName,
        sellerId: row['seller_id'] as String,
        stock: (row['stock'] as num?)?.toInt() ?? 0,
        description: row['description'] as String?,
      );
    }).toList();
  }

  static Future<Map<String, String>> _fetchBusinessNames(List<String> sellerIds) async {
    if (sellerIds.isEmpty) return {};
    final rows = await supabase
        .from('profiles_public')
        .select('id, business_name')
        .inFilter('id', sellerIds);
    final map = <String, String>{};
    for (final row in (rows as List)) {
      map[row['id'] as String] = (row['business_name'] as String?) ?? 'Seller';
    }
    return map;
  }

  static ProductCategory _categoryFromString(String s) {
    return ProductCategory.values.firstWhere(
      (c) => c.name == s || c.name.toLowerCase() == s.toLowerCase(),
      orElse: () => ProductCategory.other,
    );
  }

  /// Seller: create a new listing under their own account.
  static Future<void> createListing({
    required String name,
    required double price,
    required String unit,
    required int stock,
    required ProductCategory category,
    String? imageUrl,
    String? description,
  }) async {
    final sellerId = supabase.auth.currentUser!.id;
    await supabase.from('listings').insert({
      'seller_id': sellerId,
      'name': name,
      'price': price,
      'unit': unit,
      'stock': stock,
      'category': category.name,
      'status': 'active',
      'image_url': imageUrl,
      'description': description,
    });
  }

  /// Uploads a listing photo to the `listing-images` storage bucket and
  /// returns its public URL, for display in ProductCard/Cart/Checkout.
  static Future<String> uploadListingImage(Uint8List bytes, String fileExt) async {
    final sellerId = supabase.auth.currentUser!.id;
    final path = '$sellerId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await supabase.storage.from('listing-images').uploadBinary(path, bytes);
    return supabase.storage.from('listing-images').getPublicUrl(path);
  }

  /// Seller: fetch only their own listings (for the My Listings screen).
  static Future<List<Map<String, dynamic>>> fetchMyListings() async {
    final sellerId = supabase.auth.currentUser!.id;
    final rows = await supabase
        .from('listings')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<void> updateListingStatus(String listingId, String status) async {
    await supabase.from('listings').update({'status': status}).eq('id', listingId);
  }

  /// Seller: edit an existing listing's details.
  static Future<void> updateListing({
    required String listingId,
    required String name,
    required double price,
    required String unit,
    required int stock,
    required ProductCategory category,
    String? imageUrl,
    String? description,
  }) async {
    await supabase.from('listings').update({
      'name': name,
      'price': price,
      'unit': unit,
      'stock': stock,
      'category': category.name,
      'image_url': imageUrl,
      'description': description,
    }).eq('id', listingId);
  }
}