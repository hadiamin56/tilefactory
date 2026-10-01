import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../../repositories/cart_repository.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<CartItem>> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartFuture = CartRepository.fetchCart();
  }

  Future<void> _refresh() async {
    setState(() => _cartFuture = CartRepository.fetchCart());
    await _cartFuture;
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    await CartRepository.updateQuantity(item.id, quantity);
    _refresh();
  }

  Future<void> _remove(CartItem item) async {
    await CartRepository.removeItem(item.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CartItem>>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Cart')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Cart')),
            body: Center(child: Text('Could not load cart: ${snapshot.error}', style: const TextStyle(color: AppColors.textGrey))),
          );
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Cart')),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textGrey)),
                  SizedBox(height: 12),
                  Center(child: Text('Your cart is empty', style: TextStyle(color: AppColors.textGrey))),
                ],
              ),
            ),
          );
        }

        final bySeller = <String, List<CartItem>>{};
        for (final item in items) {
          bySeller.putIfAbsent(item.sellerName, () => []).add(item);
        }
        final grandTotal = items.fold<double>(0, (sum, it) => sum + it.total);

        return Scaffold(
          appBar: AppBar(title: const Text('My Cart')),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in bySeller.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.store_rounded, size: 16, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                        for (final item in entry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CartItemCard(
                              item: item,
                              onQuantityChanged: (q) => _updateQuantity(item, q),
                              onRemove: () => _remove(item),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                            Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(items: items)));
                          _refresh();
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemCard({required this.item, required this.onQuantityChanged, required this.onRemove});

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text('₹${item.unitPrice.toStringAsFixed(0)} / ${item.unit}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StepperButton(icon: Icons.remove, onTap: () => onQuantityChanged(item.quantity - 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: item.quantity < item.stock ? () => onQuantityChanged(item.quantity + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border.withValues(alpha: 0.3) : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: onTap == null ? AppColors.textGrey : AppColors.primary),
      ),
    );
  }
}
