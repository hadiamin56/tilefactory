import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../../repositories/listing_repository.dart';
import '../../repositories/cart_repository.dart';
import '../../widgets/product_grid_card.dart';
import '../messages/chat_screen.dart';
import '../cart/cart_screen.dart';
import 'product_detail_screen.dart';

enum _SortOption { newest, priceLowHigh, priceHighLow }

class BuyInputsScreen extends StatefulWidget {
  const BuyInputsScreen({super.key});

  @override
  State<BuyInputsScreen> createState() => _BuyInputsScreenState();
}

class _BuyInputsScreenState extends State<BuyInputsScreen> {
  ProductCategory? _categoryFilter;
  String? _sellerFilter;
  _SortOption _sort = _SortOption.newest;
  String _search = '';
  late Future<List<Product>> _listingsFuture;
  late Future<int> _cartCountFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = ListingRepository.fetchActiveListings();
    _cartCountFuture = CartRepository.fetchItemCount();
  }

  Future<void> _refresh() async {
    setState(() {
      _listingsFuture = ListingRepository.fetchActiveListings();
      _cartCountFuture = CartRepository.fetchItemCount();
    });
    await _listingsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Inputs'),
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _SortOption.newest, child: Text('Newest')),
              PopupMenuItem(value: _SortOption.priceLowHigh, child: Text('Price: Low to High')),
              PopupMenuItem(value: _SortOption.priceHighLow, child: Text('Price: High to Low')),
            ],
          ),
          FutureBuilder<int>(
            future: _cartCountFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                      _refresh();
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}', onRetry: _refresh);
          }
          final all = snapshot.data ?? [];
          if (all.isEmpty) {
            return _EmptyState(onRetry: _refresh);
          }

          final sellers = all.map((p) => p.sellerName).toSet().toList()..sort();

          var items = _categoryFilter == null ? all : all.where((p) => p.category == _categoryFilter).toList();
          if (_sellerFilter != null) {
            items = items.where((p) => p.sellerName == _sellerFilter).toList();
          }
          if (_search.trim().isNotEmpty) {
            final q = _search.trim().toLowerCase();
            items = items.where((p) => p.name.toLowerCase().contains(q)).toList();
          }
          switch (_sort) {
            case _SortOption.priceLowHigh:
              items = [...items]..sort((a, b) => a.price.compareTo(b.price));
              break;
            case _SortOption.priceHighLow:
              items = [...items]..sort((a, b) => b.price.compareTo(a.price));
              break;
            case _SortOption.newest:
              break;
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'Search fertilizers, tools, boxes...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(label: 'All', selected: _categoryFilter == null, onTap: () => setState(() => _categoryFilter = null)),
                      for (final c in ProductCategory.values)
                        _FilterChip(
                          label: c.name[0].toUpperCase() + c.name.substring(1),
                          selected: _categoryFilter == c,
                          onTap: () => setState(() => _categoryFilter = c),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: 'All Sellers',
                        selected: _sellerFilter == null,
                        onTap: () => setState(() => _sellerFilter = null),
                        icon: Icons.store_rounded,
                      ),
                      for (final s in sellers)
                        _FilterChip(label: s, selected: _sellerFilter == s, onTap: () => setState(() => _sellerFilter = s), icon: Icons.store_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No listings match your filters', style: TextStyle(color: AppColors.textGrey)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, i) => ProductGridCard(
                            product: items[i],
                            onAddToCart: () => _showAddToCartSheet(context, items[i]),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: items[i])));
                              _refresh();
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddToCartSheet(BuildContext context, Product product) {
    int quantity = 1;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: Text('Sold by ${product.sellerName}', style: const TextStyle(color: AppColors.textGrey))),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: product.sellerId, otherUserName: product.sellerName)));
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Message'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product.price.toStringAsFixed(0)} / ${product.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1 ? () => setSheetState(() => quantity--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        IconButton(
                          onPressed: quantity < product.stock ? () => setSheetState(() => quantity++) : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Total: ₹${(product.price * quantity).toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await CartRepository.addToCart(product.id, quantity);
                        if (!mounted) return;
                        setState(() => _cartCountFuture = CartRepository.fetchItemCount());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${product.name} × $quantity to cart')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not add to cart — please try again')),
                        );
                      }
                    },
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon != null ? Icon(icon, size: 14, color: selected ? AppColors.primary : AppColors.textGrey) : null,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 12.5),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textGrey),
          const SizedBox(height: 12),
          const Text('No input listings yet', style: TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            const Text('Could not load listings', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: AppColors.textGrey, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
