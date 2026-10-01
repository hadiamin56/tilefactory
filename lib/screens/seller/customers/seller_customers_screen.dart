import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../repositories/seller_customer_repository.dart';

class SellerCustomersScreen extends StatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  State<SellerCustomersScreen> createState() => _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends State<SellerCustomersScreen> {
  late Future<List<SellerCustomer>> _customersFuture;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _customersFuture = SellerCustomerRepository.fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customers')),
      body: FutureBuilder<List<SellerCustomer>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded, size: 44, color: AppColors.textGrey),
                    SizedBox(height: 10),
                    Text('No customers yet', style: TextStyle(color: AppColors.textGrey)),
                    SizedBox(height: 4),
                    Text('Growers who order from you will show up here', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
            );
          }
          final customers = _search.trim().isEmpty
              ? all
              : all.where((c) => c.growerName.toLowerCase().contains(_search.trim().toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(hintText: 'Search customers...', prefixIcon: Icon(Icons.search, size: 20)),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final c = customers[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 22, backgroundColor: AppColors.primaryLight, child: Icon(Icons.person, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.growerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 3),
                                Text('${c.orderCount} order${c.orderCount == 1 ? '' : 's'} · Last ${DateFormat('d MMM').format(c.lastOrderAt)}', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('₹${c.totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
