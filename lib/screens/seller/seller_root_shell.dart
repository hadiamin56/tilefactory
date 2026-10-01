import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dashboard/seller_dashboard_screen.dart';
import 'listings/seller_listings_screen.dart';
import 'orders/seller_orders_screen.dart';
import 'profile/seller_profile_screen.dart';

class SellerRootShell extends StatefulWidget {
  const SellerRootShell({super.key});

  @override
  State<SellerRootShell> createState() => _SellerRootShellState();
}

class _SellerRootShellState extends State<SellerRootShell> {
  int _index = 0;

  final _screens = const [
    SellerDashboardScreen(),
    SellerListingsScreen(),
    SellerOrdersScreen(),
    SellerProfileScreen(),
  ];

  final _items = const [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.list_alt_rounded, 'Listings'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.store_rounded, 'Store'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.lifted,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = _index == i;
                final item = _items[i];
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$1, size: 22, color: selected ? AppColors.primary : AppColors.textGrey),
                        if (selected) ...[
                          const SizedBox(width: 7),
                          Text(item.$2, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
