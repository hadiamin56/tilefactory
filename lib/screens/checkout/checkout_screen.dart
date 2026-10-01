import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../main.dart';
import '../../models/cart_item.dart';
import '../../repositories/cart_repository.dart';
import '../orders/orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saveAsDefault = false;
  bool _loading = false;
  bool _prefillLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final userId = supabase.auth.currentUser!.id;
    final profile = await supabase.from('profiles').select('full_name, phone, saved_address').eq('id', userId).maybeSingle();
    if (!mounted) return;
    setState(() {
      _nameController.text = (profile?['full_name'] as String?) ?? '';
      _phoneController.text = (profile?['phone'] as String?) ?? '';
      _addressController.text = (profile?['saved_address'] as String?) ?? '';
      _prefillLoading = false;
    });
  }

  Future<void> _placeOrder() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name, phone and address')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      if (_saveAsDefault) {
        await CartRepository.saveDefaultAddress(address);
      }
      final orderCount = await CartRepository.checkout(
        items: widget.items,
        deliveryName: name,
        deliveryPhone: phone,
        deliveryAddress: address,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 44),
          title: Text(orderCount > 1 ? 'Orders Placed!' : 'Order Placed!'),
          content: Text(
            orderCount > 1
                ? 'Your items were split into $orderCount orders across different sellers.'
                : 'Your order has been placed successfully.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
              },
              child: const Text('View Orders'),
            ),
          ],
        ),
      );
    } on InsufficientBalanceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient wallet balance — you need ₹${e.shortfall.toStringAsFixed(0)} more to place this order')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not place order — please try again')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bySeller = <String, List<CartItem>>{};
    for (final item in widget.items) {
      bySeller.putIfAbsent(item.sellerName, () => []).add(item);
    }
    final grandTotal = widget.items.fold<double>(0, (sum, it) => sum + it.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _prefillLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 12),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Full Address', hintText: 'House no, street, village/town, district, PIN'),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _saveAsDefault,
                  onChanged: (v) => setState(() => _saveAsDefault = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Save as my default address', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 12),
                for (final entry in bySeller.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.store_rounded, size: 15, color: AppColors.textGrey),
                        const SizedBox(width: 6),
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  ...entry.value.map((it) => Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${it.productName} x${it.quantity}', style: const TextStyle(fontSize: 13))),
                            Text('₹${it.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.primary)),
                  ],
                ),
                if (bySeller.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'These items are from ${bySeller.length} different sellers, so ${bySeller.length} separate orders will be created.',
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading || _prefillLoading ? null : _placeOrder,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Place Order'),
            ),
          ),
        ),
      ),
    );
  }
}
