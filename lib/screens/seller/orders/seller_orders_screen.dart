import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../repositories/order_repository.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  String? _filter;
  bool _kanban = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderRepository.fetchIncomingOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = OrderRepository.fetchIncomingOrders();
    });
    await _ordersFuture;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.amber;
      case 'confirmed':
        return AppColors.blue;
      case 'shipped':
        return AppColors.purple;
      case 'delivered':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.red;
      default:
        return AppColors.textGrey;
    }
  }

  String? _nextStatus(String status) {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'shipped';
      case 'shipped':
        return 'delivered';
      default:
        return null;
    }
  }

  String _nextActionLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Confirm Order';
      case 'confirmed':
        return 'Mark Shipped';
      case 'shipped':
        return 'Mark Delivered';
      default:
        return '';
    }
  }

  bool _canCancel(String status) => status == 'pending' || status == 'confirmed';

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('This will cancel the order and refund the grower. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Reject', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await OrderRepository.sellerCancelOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order rejected and grower refunded')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not reject this order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: Icon(_kanban ? Icons.view_list_rounded : Icons.view_kanban_outlined),
            tooltip: _kanban ? 'List view' : 'Board view',
            onPressed: () => setState(() => _kanban = !_kanban),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data ?? [];
            if (_kanban) {
              return _KanbanBoard(
                orders: all,
                statusColor: _statusColor,
                nextStatus: _nextStatus,
                nextActionLabel: _nextActionLabel,
                canCancel: _canCancel,
                onAdvance: (id, next) async {
                  await OrderRepository.updateOrderStatus(id, next);
                  _refresh();
                },
                onCancel: _cancelOrder,
              );
            }
            final orders = _filter == null ? all : all.where((o) => o['status'] == _filter).toList();
            final filterRow = Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _OrderFilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                    const SizedBox(width: 8),
                    _OrderFilterChip(label: 'Pending', selected: _filter == 'pending', onTap: () => setState(() => _filter = 'pending')),
                    const SizedBox(width: 8),
                    _OrderFilterChip(label: 'Confirmed', selected: _filter == 'confirmed', onTap: () => setState(() => _filter = 'confirmed')),
                    const SizedBox(width: 8),
                    _OrderFilterChip(label: 'Shipped', selected: _filter == 'shipped', onTap: () => setState(() => _filter = 'shipped')),
                    const SizedBox(width: 8),
                    _OrderFilterChip(label: 'Delivered', selected: _filter == 'delivered', onTap: () => setState(() => _filter = 'delivered')),
                  ],
                ),
              ),
            );
            if (all.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textGrey)),
                  SizedBox(height: 12),
                  Center(child: Text('No orders yet', style: TextStyle(color: AppColors.textGrey))),
                ],
              );
            }
            if (orders.isEmpty) {
              return Column(
                children: [
                  filterRow,
                  const Expanded(child: Center(child: Text('No orders in this filter', style: TextStyle(color: AppColors.textGrey)))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: orders.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) return filterRow;
                final o = orders[i - 1];
                final status = o['status'] as String;
                final color = _statusColor(status);
                final items = (o['order_items'] as List);
                final next = _nextStatus(status);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${(o['id'] as String).substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o['grower_name'] ?? 'Grower'} · ${DateFormat('d MMM yyyy').format(DateTime.parse(o['created_at'] as String))}',
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ...items.map((it) => Text('${it['product_name']} x${it['quantity']}')),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\u20B9${(o['total'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Row(
                            children: [
                              if (_canCancel(status)) ...[
                                OutlinedButton(
                                  onPressed: () => _cancelOrder(o['id'] as String),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (next != null)
                                ElevatedButton(
                                  onPressed: () async {
                                    await OrderRepository.updateOrderStatus(o['id'] as String, next);
                                    _refresh();
                                  },
                                  child: Text(_nextActionLabel(status)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Color Function(String) statusColor;
  final String? Function(String) nextStatus;
  final String Function(String) nextActionLabel;
  final bool Function(String) canCancel;
  final Future<void> Function(String orderId, String nextStatus) onAdvance;
  final Future<void> Function(String orderId) onCancel;

  const _KanbanBoard({
    required this.orders,
    required this.statusColor,
    required this.nextStatus,
    required this.nextActionLabel,
    required this.canCancel,
    required this.onAdvance,
    required this.onCancel,
  });

  static const _columns = ['pending', 'confirmed', 'shipped', 'delivered'];
  static const _columnLabels = {'pending': 'Pending', 'confirmed': 'Confirmed', 'shipped': 'Shipped', 'delivered': 'Delivered'};

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet', style: TextStyle(color: AppColors.textGrey)));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _columns.map((status) {
          final columnOrders = orders.where((o) => o['status'] == status).toList();
          final color = statusColor(status);
          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Text(_columnLabels[status]!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text('${columnOrders.length}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (columnOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('—', style: TextStyle(color: AppColors.textGrey))),
                  )
                else
                  ...columnOrders.map((o) {
                    final items = (o['order_items'] as List);
                    final next = nextStatus(status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.soft),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#${(o['id'] as String).substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 3),
                          Text(o['grower_name'] as String? ?? 'Grower', style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5)),
                          const SizedBox(height: 6),
                          if (items.isNotEmpty)
                            Text('${items[0]['product_name']}${items.length > 1 ? ' +${items.length - 1} more' : ''}', style: const TextStyle(fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text('₹${(o['total'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primary)),
                          if (next != null) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6), textStyle: const TextStyle(fontSize: 11)),
                                onPressed: () => onAdvance(o['id'] as String, next),
                                child: Text(nextActionLabel(status)),
                              ),
                            ),
                          ],
                          if (canCancel(status)) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11),
                                  foregroundColor: AppColors.red,
                                  side: const BorderSide(color: AppColors.red),
                                ),
                                onPressed: () => onCancel(o['id'] as String),
                                child: const Text('Reject'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OrderFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 12.5),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }
}