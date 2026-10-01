import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/product.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/review_repository.dart';
import '../../repositories/cart_repository.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Grower-facing read-only view of a seller's storefront — reached by
/// tapping the seller row on a Product Detail page. Only shows fields the
/// public is allowed to see (via `profiles_public`) plus real reviews.
class SellerStoreScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  const SellerStoreScreen({super.key, required this.sellerId, required this.sellerName});

  @override
  State<SellerStoreScreen> createState() => _SellerStoreScreenState();
}

class _SellerStoreScreenState extends State<SellerStoreScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<ReviewSummary> _summaryFuture;
  late Future<List<Product>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = supabase.from('profiles_public').select('business_name, is_verified, created_at').eq('id', widget.sellerId).maybeSingle();
    _summaryFuture = ReviewRepository.fetchSummaryForSeller(widget.sellerId);
    _listingsFuture = ListingRepository.fetchListingsBySeller(widget.sellerId, sellerName: widget.sellerName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.sellerName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final isVerified = profile?['is_verified'] as bool? ?? false;
              final memberSince = profile?['created_at'] != null ? DateFormat('MMM yyyy').format(DateTime.parse(profile!['created_at'] as String)) : null;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 28, backgroundColor: AppColors.primaryLight, child: Icon(Icons.store, color: AppColors.primary, size: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                              if (isVerified) ...[
                                const SizedBox(width: 5),
                                const Icon(Icons.verified, size: 16, color: AppColors.primary),
                              ],
                            ],
                          ),
                          if (memberSince != null) ...[
                            const SizedBox(height: 3),
                            Text('Member since $memberSince', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                          ],
                          const SizedBox(height: 5),
                          FutureBuilder<ReviewSummary>(
                            future: _summaryFuture,
                            builder: (context, summarySnap) {
                              final summary = summarySnap.data ?? ReviewSummary.empty;
                              return Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
                                  const SizedBox(width: 3),
                                  Text(
                                    summary.count == 0 ? 'No reviews yet' : '${summary.average.toStringAsFixed(1)} (${summary.count} review${summary.count == 1 ? '' : 's'})',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          const SizedBox(height: 12),
          FutureBuilder<List<Product>>(
            future: _listingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator()));
              }
              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No active listings', style: TextStyle(color: AppColors.textGrey))),
                );
              }
              return Column(
                children: listings.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProductCard(
                      product: p,
                      onAddToCart: () async {
                        await CartRepository.addToCart(p.id, 1);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${p.name} to cart')));
                      },
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
