import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/review_repository.dart';
import '../messages/chat_screen.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';
import 'seller_store_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _busy = false;
  late final Future<ReviewSummary> _sellerSummaryFuture = ReviewRepository.fetchSummaryForSeller(widget.product.sellerId);

  Future<void> _addToCart({bool goToCheckout = false}) async {
    setState(() => _busy = true);
    try {
      await CartRepository.addToCart(widget.product.id, _quantity);
      if (!mounted) return;
      if (goToCheckout) {
        final cart = await CartRepository.fetchCart();
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(items: cart)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.product.name} × $_quantity to cart'),
            action: SnackBarAction(label: 'View Cart', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add to cart — please try again')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final outOfStock = product.stock <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textDark,
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _heroPlaceholder(product),
                    )
                  : _heroPlaceholder(product),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(product.unit, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text('/ ${product.unit}', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                  Text(
                    outOfStock ? 'Out of stock' : '${product.stock} available',
                    style: TextStyle(color: outOfStock ? AppColors.red : AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _TrustBadge(icon: Icons.verified_rounded, label: 'Verified Seller'),
                      const SizedBox(width: 10),
                      _TrustBadge(icon: Icons.local_shipping_outlined, label: 'Direct Delivery'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Product Description', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                  const SizedBox(height: 8),
                  Text(
                    (product.description != null && product.description!.trim().isNotEmpty)
                        ? product.description!
                        : 'No description provided by the seller yet.',
                    style: const TextStyle(color: AppColors.textGrey, height: 1.5, fontSize: 13.5),
                  ),
                  const SizedBox(height: 22),
                  const Text('Seller', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SellerStoreScreen(sellerId: product.sellerId, sellerName: product.sellerName)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                            child: const Icon(Icons.store_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.sellerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 3),
                                FutureBuilder<ReviewSummary>(
                                  future: _sellerSummaryFuture,
                                  builder: (context, snapshot) {
                                    final summary = snapshot.data ?? ReviewSummary.empty;
                                    return Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                        const SizedBox(width: 3),
                                        Text(
                                          summary.count == 0 ? 'No reviews yet' : '${summary.average.toStringAsFixed(1)} (${summary.count})',
                                          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: product.sellerId, otherUserName: product.sellerName)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!outOfStock) ...[
                    const SizedBox(height: 22),
                    const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QtyButton(icon: Icons.remove, onTap: _quantity > 1 ? () => setState(() => _quantity--) : null),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text('$_quantity', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                        _QtyButton(icon: Icons.add, onTap: _quantity < product.stock ? () => setState(() => _quantity++) : null),
                      ],
                    ),
                  ],
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: outOfStock
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _addToCart(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : () => _addToCart(goToCheckout: true),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: _busy
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Buy Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _heroPlaceholder(Product product) {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(child: Icon(Icons.inventory_2_outlined, size: 72, color: AppColors.primary)),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border.withValues(alpha: 0.3) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? AppColors.textGrey : AppColors.primary),
      ),
    );
  }
}
