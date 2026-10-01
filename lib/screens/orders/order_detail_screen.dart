import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/order.dart';
import '../../repositories/review_repository.dart';

class OrderDetailScreen extends StatefulWidget {
  final GrowerOrder order;
  const OrderDetailScreen({super.key, required this.order});

  static const steps = [OrderStatus.pending, OrderStatus.confirmed, OrderStatus.shipped, OrderStatus.delivered];

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<bool> _hasReviewFuture;

  @override
  void initState() {
    super.initState();
    _hasReviewFuture = widget.order.status == OrderStatus.delivered
        ? ReviewRepository.hasReview(widget.order.id)
        : Future.value(true);
  }

  Future<void> _showRateSheet() async {
    int rating = 5;
    final commentController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate this order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('From ${widget.order.sellerName}', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    return IconButton(
                      onPressed: () => setSheetState(() => rating = starValue),
                      icon: Icon(
                        starValue <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.amber,
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Share your experience (optional)'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheetState(() => saving = true);
                            try {
                              await ReviewRepository.submitReview(
                                orderId: widget.order.id,
                                sellerId: widget.order.sellerId,
                                rating: rating,
                                comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                              );
                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              setState(() => _hasReviewFuture = Future.value(true));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Could not submit review')));
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final cancelled = order.status == OrderStatus.cancelled;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id.substring(0, 8).toUpperCase()}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
            child: cancelled
                ? const Row(
                    children: [
                      Icon(Icons.cancel_rounded, color: AppColors.red),
                      SizedBox(width: 10),
                      Text('Order Cancelled', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.red)),
                    ],
                  )
                : _StatusTracker(current: order.status),
          ),
          const SizedBox(height: 20),
          Text('From ${order.sellerName} · ${DateFormat('d MMM yyyy, h:mm a').format(order.date)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
          const SizedBox(height: 20),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
            child: Column(
              children: [
                ...order.items.map((it) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${it.productName} x${it.quantity}')),
                          Text('₹${it.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('₹${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.deliveryName != null) Text(order.deliveryName!, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (order.deliveryPhone != null) ...[
                    const SizedBox(height: 4),
                    Text(order.deliveryPhone!, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  ],
                  const SizedBox(height: 4),
                  Text(order.deliveryAddress!, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                ],
              ),
            ),
          ],
          if (order.status == OrderStatus.delivered)
            FutureBuilder<bool>(
              future: _hasReviewFuture,
              builder: (context, snapshot) {
                if (snapshot.data == true) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showRateSheet,
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Rate this order'),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final OrderStatus current;
  const _StatusTracker({required this.current});

  static const _labels = {
    OrderStatus.pending: 'Placed',
    OrderStatus.confirmed: 'Confirmed',
    OrderStatus.shipped: 'Shipped',
    OrderStatus.delivered: 'Delivered',
  };

  static const _icons = {
    OrderStatus.pending: Icons.receipt_long_rounded,
    OrderStatus.confirmed: Icons.check_circle_rounded,
    OrderStatus.shipped: Icons.local_shipping_rounded,
    OrderStatus.delivered: Icons.home_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final steps = OrderDetailScreen.steps;
    final currentIndex = steps.indexOf(current);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftIndex = i ~/ 2;
          final done = leftIndex < currentIndex;
          return Expanded(child: Container(height: 3, color: done ? AppColors.primary : AppColors.border));
        }
        final stepIndex = i ~/ 2;
        final step = steps[stepIndex];
        final reached = stepIndex <= currentIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: reached ? AppColors.primary : AppColors.border, shape: BoxShape.circle),
              child: Icon(_icons[step], color: reached ? Colors.white : AppColors.textGrey, size: 16),
            ),
            const SizedBox(height: 6),
            Text(_labels[step]!, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: reached ? AppColors.primary : AppColors.textGrey)),
          ],
        );
      }),
    );
  }
}
